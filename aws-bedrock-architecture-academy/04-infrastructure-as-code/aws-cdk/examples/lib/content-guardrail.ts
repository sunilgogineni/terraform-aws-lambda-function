import { createHash } from 'node:crypto';
import { Token } from 'aws-cdk-lib';
import * as bedrock from 'aws-cdk-lib/aws-bedrock';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';

/** Filter strength values accepted by the CreateGuardrail API (`GuardrailFilterStrength`). */
export enum FilterStrength {
  NONE = 'NONE',
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
}

/** A topic the guardrail must refuse to discuss. */
export interface DeniedTopic {
  /** Short name, for example `InvestmentAdvice`. */
  readonly name: string;
  /** One or two sentences that define the topic for the classifier. */
  readonly definition: string;
  /** @default - no examples */
  readonly examples?: string[];
}

/**
 * Properties for {@link ContentGuardrail}. Every optional property has a documented default,
 * so `new ContentGuardrail(this, 'Guardrail')` is already a useful, safe configuration.
 */
export interface ContentGuardrailProps {
  /**
   * Guardrail name. Letters, digits, hyphens and underscores, at most 50 characters.
   * @default - derived from the construct path, so two instances never collide
   */
  readonly guardrailName?: string;

  /** @default - no description */
  readonly description?: string;

  /**
   * Strength of the five harmful-content filters (sexual, violence, hate, insults, misconduct),
   * applied to both prompts and responses.
   * @default FilterStrength.HIGH
   */
  readonly harmfulContentStrength?: FilterStrength;

  /**
   * Add the prompt-attack filter on user input.
   * @default true
   */
  readonly blockPromptAttacks?: boolean;

  /**
   * Topics to deny. At most 30 (the alpha L2 documents the same limit).
   * @default - none
   */
  readonly deniedTopics?: DeniedTopic[];

  /**
   * PII entity types (`GuardrailPiiEntityType` values such as `EMAIL`) to anonymize.
   * @default ['EMAIL', 'PHONE']
   */
  readonly anonymizePiiTypes?: string[];

  /** @default 'Sorry, I cannot help with that request.' */
  readonly blockedInputMessaging?: string;

  /** @default 'Sorry, I cannot share that response.' */
  readonly blockedOutputsMessaging?: string;

  /**
   * Customer managed key for the guardrail.
   * @default - encrypted with an AWS managed key
   */
  readonly encryptionKey?: kms.IKey;
}

const NAME_PATTERN = /^[0-9a-zA-Z_-]{1,50}$/;
const HARMFUL_CATEGORIES = ['SEXUAL', 'VIOLENCE', 'HATE', 'INSULTS', 'MISCONDUCT'];

/**
 * An Amazon Bedrock guardrail plus an immutable, published version of it.
 *
 * Built on the L1 `CfnGuardrail` and `CfnGuardrailVersion` (ADR-012: no stable L2 exists).
 * A new version is published whenever the policy configuration changes, because the
 * version's description carries a hash of that configuration and `Description` is a
 * create-only property of `AWS::Bedrock::GuardrailVersion`.
 */
export class ContentGuardrail extends Construct {
  /** ARN of the guardrail (without a version suffix). */
  public readonly guardrailArn: string;
  /** Guardrail ID, for the `guardrailIdentifier` field of Converse and ApplyGuardrail. */
  public readonly guardrailId: string;
  /** The published version number, for the `guardrailVersion` field. */
  public readonly guardrailVersion: string;
  /** Escape hatch: the underlying L1 resource. */
  public readonly cfnGuardrail: bedrock.CfnGuardrail;

  constructor(scope: Construct, id: string, props: ContentGuardrailProps = {}) {
    super(scope, id);

    // 1. Validate early, so mistakes fail at synth time instead of during deployment.
    const name = props.guardrailName ?? defaultName(this);
    if (!Token.isUnresolved(name) && !NAME_PATTERN.test(name)) {
      throw new Error(`guardrailName must match ${NAME_PATTERN}, got '${name}'`);
    }
    const topics = props.deniedTopics ?? [];
    if (topics.length > 30) {
      throw new Error(`At most 30 denied topics are allowed, got ${topics.length}`);
    }
    const piiTypes = props.anonymizePiiTypes ?? ['EMAIL', 'PHONE'];
    const strength = props.harmfulContentStrength ?? FilterStrength.HIGH;
    const blockPromptAttacks = props.blockPromptAttacks ?? true;
    if (strength === FilterStrength.NONE && !blockPromptAttacks && topics.length === 0 && piiTypes.length === 0) {
      throw new Error('The guardrail would have no active policy; enable at least one filter');
    }

    // 2. Build the policy configuration once; it is used for the resource and for the version hash.
    const filtersConfig: bedrock.CfnGuardrail.ContentFilterConfigProperty[] = HARMFUL_CATEGORIES.map((type) => ({
      type,
      inputStrength: strength,
      outputStrength: strength,
    }));
    if (blockPromptAttacks) {
      // Prompt attacks are user input; the API example on the prompt-attack page sets the input side only.
      filtersConfig.push({ type: 'PROMPT_ATTACK', inputStrength: FilterStrength.HIGH, outputStrength: FilterStrength.NONE });
    }
    const policy = {
      contentPolicyConfig: { filtersConfig },
      topicPolicyConfig: topics.length
        ? { topicsConfig: topics.map((t) => ({ name: t.name, definition: t.definition, examples: t.examples, type: 'DENY' })) }
        : undefined,
      sensitiveInformationPolicyConfig: piiTypes.length
        ? { piiEntitiesConfig: piiTypes.map((type) => ({ type, action: 'ANONYMIZE' })) }
        : undefined,
    };

    // 3. Create the resources. 'Resource' is the conventional ID of the primary L1 child,
    //    so `node.defaultChild` returns it and the logical ID stays short.
    this.cfnGuardrail = new bedrock.CfnGuardrail(this, 'Resource', {
      name,
      description: props.description,
      blockedInputMessaging: props.blockedInputMessaging ?? 'Sorry, I cannot help with that request.',
      blockedOutputsMessaging: props.blockedOutputsMessaging ?? 'Sorry, I cannot share that response.',
      kmsKeyArn: props.encryptionKey?.keyArn,
      ...policy,
    });

    const configHash = createHash('sha256').update(JSON.stringify(policy)).digest('hex').slice(0, 12);
    const version = new bedrock.CfnGuardrailVersion(this, 'Version', {
      guardrailIdentifier: this.cfnGuardrail.attrGuardrailId,
      description: `Published by the AWS CDK; configuration ${configHash}`,
    });

    // 4. Expose what callers need; never make them reach into the construct tree.
    this.guardrailArn = this.cfnGuardrail.attrGuardrailArn;
    this.guardrailId = this.cfnGuardrail.attrGuardrailId;
    this.guardrailVersion = version.attrVersion;
  }

  /** Allow a principal to apply this guardrail (`bedrock:ApplyGuardrail` on its ARN). */
  public grantApply(grantee: iam.IGrantable): iam.Grant {
    return iam.Grant.addToPrincipal({
      grantee,
      actions: ['bedrock:ApplyGuardrail'],
      resourceArns: [this.guardrailArn],
    });
  }
}

function defaultName(scope: Construct): string {
  const path = scope.node.path.replace(/[^0-9a-zA-Z_-]/g, '-');
  const hash = createHash('sha256').update(scope.node.path).digest('hex').slice(0, 8);
  return `${path.slice(0, 50 - hash.length - 1)}-${hash}`;
}

