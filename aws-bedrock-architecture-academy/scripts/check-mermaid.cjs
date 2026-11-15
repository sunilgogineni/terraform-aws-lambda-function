#!/usr/bin/env node
/*
 * Validate (and optionally render) every Mermaid diagram in the academy.
 *
 * Usage:
 *   node scripts/check-mermaid.cjs [PATH ...] [--render OUT_DIR] [--quiet]
 *
 * - Extracts ```mermaid fenced blocks from Markdown files and the whole body
 *   of *.mmd files.
 * - Parses AND renders each diagram in headless Chromium with every Mermaid
 *   bundle it can find, so a diagram must work on an older Mermaid (what a
 *   Markdown host may still run) as well as the newest one.
 * - --render OUT_DIR writes one SVG per diagram found under diagrams/mermaid/
 *   using the newest bundle.
 *
 * Mermaid bundles are discovered from, in order:
 *   1. $MERMAID_BUNDLES  (":"-separated paths to mermaid.min.js files)
 *   2. scripts/node_modules/mermaid/dist/mermaid.min.js   (after `npm ci` in scripts/)
 *   3. $ACADEMY_TOOLS/node*\/node_modules/mermaid/dist/mermaid.min.js
 *
 * Requires: playwright (Chromium). Exit code 1 if any diagram fails.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SKIP_DIRS = new Set(['node_modules', '.terraform', 'cdk.out', '.git', '.venv', '__pycache__', '.validation', 'rendered']);

function parseArgs(argv) {
  const opts = { paths: [], render: null, quiet: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--render') opts.render = path.resolve(argv[++i]);
    else if (a === '--quiet') opts.quiet = true;
    else opts.paths.push(path.resolve(a));
  }
  if (opts.paths.length === 0) opts.paths.push(ROOT);
  return opts;
}

function walk(p, out) {
  const st = fs.statSync(p);
  if (st.isFile()) {
    if (/\.(md|mmd)$/i.test(p)) out.push(p);
    return;
  }
  for (const name of fs.readdirSync(p)) {
    if (SKIP_DIRS.has(name)) continue;
    walk(path.join(p, name), out);
  }
}

function extractBlocks(file) {
  const text = fs.readFileSync(file, 'utf8');
  if (/\.mmd$/i.test(file)) return [{ file, line: 1, index: 1, code: text }];
  const blocks = [];
  const lines = text.split(/\r?\n/);
  let inBlock = false;
  let fence = '';
  let start = 0;
  let buf = [];
  let index = 0;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!inBlock) {
      const m = line.match(/^\s*(`{3,}|~{3,})\s*mermaid\s*$/i);
      if (m) { inBlock = true; fence = m[1]; start = i + 2; buf = []; }
    } else if (line.trim().startsWith(fence) && line.trim().replace(/[`~]/g, '') === '') {
      inBlock = false;
      index += 1;
      blocks.push({ file, line: start, index, code: buf.join('\n') });
    } else {
      buf.push(line);
    }
  }
  if (inBlock) blocks.push({ file, line: start, index: index + 1, code: buf.join('\n'), unterminated: true });
  return blocks;
}

function findBundles() {
  const found = [];
  const add = (p) => { if (p && fs.existsSync(p) && !found.includes(p)) found.push(p); };
  if (process.env.MERMAID_BUNDLES) process.env.MERMAID_BUNDLES.split(':').forEach(add);
  add(path.join(__dirname, 'node_modules', 'mermaid', 'dist', 'mermaid.min.js'));
  const tools = process.env.ACADEMY_TOOLS;
  if (tools && fs.existsSync(tools)) {
    for (const name of fs.readdirSync(tools).sort()) {
      if (name.startsWith('node')) add(path.join(tools, name, 'node_modules', 'mermaid', 'dist', 'mermaid.min.js'));
    }
  }
  return found.map((p) => {
    let version = 'unknown';
    try { version = JSON.parse(fs.readFileSync(path.join(path.dirname(p), '..', 'package.json'), 'utf8')).version; } catch (_) { /* ignore */ }
    return { path: p, version };
  }).sort((a, b) => a.version.localeCompare(b.version, undefined, { numeric: true }));
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const files = [];
  for (const p of opts.paths) walk(p, files);
  const blocks = files.sort().flatMap(extractBlocks);
  const bundles = findBundles();
  if (bundles.length === 0) {
    console.error('No Mermaid bundle found. Run `npm ci` in scripts/ or set MERMAID_BUNDLES.');
    process.exit(2);
  }
  let chromium;
  try { ({ chromium } = require('playwright')); } catch (e) {
    console.error('playwright is not installed. Run `npm ci` in scripts/.');
    process.exit(2);
  }

  const failures = [];
  for (const b of blocks) {
    if (b.unterminated) failures.push({ block: b, version: '-', message: 'unterminated ```mermaid fence' });
    if (!b.code.trim()) failures.push({ block: b, version: '-', message: 'empty diagram' });
  }

  const browser = await chromium.launch();
  const newest = bundles[bundles.length - 1];
  let rendered = 0;
  try {
    for (const bundle of bundles) {
      const page = await browser.newPage();
      await page.setContent('<!doctype html><html><body><div id="host"></div></body></html>');
      await page.addScriptTag({ path: bundle.path });
      await page.evaluate(() => {
        // eslint-disable-next-line no-undef
        mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: 'default' });
      });
      for (const b of blocks) {
        if (b.unterminated || !b.code.trim()) continue;
        const res = await page.evaluate(async ({ code, id }) => {
          try {
            // eslint-disable-next-line no-undef
            await mermaid.parse(code);
            // eslint-disable-next-line no-undef
            const out = await mermaid.render(id, code);
            return { ok: true, svg: out.svg };
          } catch (e) {
            document.querySelectorAll('[id^="d"]').forEach((n) => { if (n.id.startsWith('dmm')) n.remove(); });
            return { ok: false, message: String((e && e.message) || e).split('\n').slice(0, 6).join(' | ') };
          }
        }, { code: b.code, id: `mm${Math.random().toString(36).slice(2)}` });
        if (!res.ok) {
          failures.push({ block: b, version: bundle.version, message: res.message });
        } else if (opts.render && bundle === newest) {
          const rel = path.relative(ROOT, b.file).split(path.sep).join('/');
          if (rel.startsWith('diagrams/mermaid/')) {
            fs.mkdirSync(opts.render, { recursive: true });
            const base = path.basename(b.file).replace(/\.(md|mmd)$/i, '');
            const suffix = /\.mmd$/i.test(b.file) ? '' : `-${String(b.index).padStart(2, '0')}`;
            fs.writeFileSync(path.join(opts.render, `${base}${suffix}.svg`), res.svg);
            rendered += 1;
          }
        }
      }
      await page.close();
    }
  } finally {
    await browser.close();
  }

  const rel = (f) => path.relative(ROOT, f) || f;
  console.log(`Files scanned     : ${files.length}`);
  console.log(`Mermaid diagrams  : ${blocks.length}`);
  console.log(`Mermaid versions  : ${bundles.map((b) => b.version).join(', ')}`);
  if (opts.render) console.log(`SVGs rendered     : ${rendered} -> ${path.relative(ROOT, opts.render) || opts.render}`);
  console.log(`Failures          : ${failures.length}`);
  for (const f of failures) {
    console.log(`  FAIL ${rel(f.block.file)}:${f.block.line} (diagram #${f.block.index}, mermaid ${f.version}) ${f.message}`);
  }
  process.exit(failures.length ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(2); });
