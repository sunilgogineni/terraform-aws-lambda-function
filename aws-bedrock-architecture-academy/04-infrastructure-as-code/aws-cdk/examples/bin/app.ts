#!/usr/bin/env node
import { App } from 'aws-cdk-lib';
import { AgentMemoryStack } from '../lib/agent-memory-stack';
import { DeliveryPipelineStack } from '../lib/delivery-pipeline-stack';
import { GuardrailL1Stack } from '../lib/guardrail-l1-stack';
import { InvocationLoggingStack } from '../lib/invocation-logging-stack';

const app = new App();

/** Read a required string from cdk.json context (or `--context key=value`). */
function context(key: string): string {
  const value: unknown = app.node.tryGetContext(key);
  if (typeof value !== 'string' || value.length === 0) {
    throw new Error(`Set the context value '${key}' in cdk.json or with --context ${key}=...`);
  }
  return value;
}

// Chapter 9: environment-agnostic stacks you can synthesize and read on their own.
new GuardrailL1Stack(app, 'AcademyGuardrailL1');
new AgentMemoryStack(app, 'AcademyAgentMemory');
new InvocationLoggingStack(app, 'AcademyInvocationLogging');

// Chapter 6: a pipeline in the tooling account that deploys the chapter 9 stacks into a
// workload account. Cross-account delivery needs explicit environments.
const region = context('academy:region');
new DeliveryPipelineStack(app, 'AcademyDeliveryPipeline', {
  env: { account: context('academy:toolingAccount'), region },
  repository: context('academy:repository'),
  connectionArn: context('academy:connectionArn'),
  workloadEnv: { account: context('academy:workloadAccount'), region },
});
