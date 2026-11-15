import { Stack } from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

/**
 * Properties for {@link BedrockInvocationRole}.
 */
export interface BedrockInvocationRoleProps {
  /** Who may assume the role, for example `new iam.ServicePrincipal('lambda.amazonaws.com')`. */
  readonly assumedBy: iam.IPrincipal;

  /**
   * Foundation model IDs the role may invoke. Wildcards are rejected.
   * Confirm current IDs in the Amazon Bedrock model catalog; they change as models are retired.
   */
  readonly foundationModelIds: string[];

  /**
   * Regions in which those models may be invoked. With cross-Region inference this must
   * include every destination Region of the inference profile.
   * @default - the stack's Region only
   */
  readonly modelRegions?: string[];

  /**
   * ARNs of system-defined or application inference profiles the role may invoke.
   * @default - none: direct on-demand invocation of the models only
   */
  readonly inferenceProfileArns?: string[];

  /**
   * Allow the models only through one of `inferenceProfileArns`.
   * @default false
   */
  readonly restrictToInferenceProfiles?: boolean;

  /**
   * Also allow the Region-less foundation-model ARN that Global inference profiles require.
   * @default false
   */
  readonly allowGlobalInference?: boolean;

  /**
   * Grant `bedrock:InvokeModelWithResponseStream` (needed for ConverseStream).
   * @default true
   */
  readonly allowStreaming?: boolean;

  /**
   * Guardrail ARNs (without a version suffix) the role may apply.
   * @default - none
   */
  readonly guardrailArns?: string[];

  /**
   * When set, inference is denied unless the request uses a guardrail matching this ARN pattern,
   * for example `arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123:*`.
   * @default - no guardrail is enforced
   */
  readonly requiredGuardrailArnPattern?: string;

  /** @default - a generated name */
  readonly roleName?: string;
}

/**
 * A least-privilege IAM role for the Amazon Bedrock inference APIs
 * (Converse, ConverseStream, InvokeModel, InvokeModelWithResponseStream).
 *
 * The TypeScript twin of the Terraform module `bedrock-invocation-role`; both encode the
 * same documented IAM behaviour (see the README for sources).
 */
export class BedrockInvocationRole extends Construct {
  /** The role. Pass it to a Lambda function, an ECS task definition, and so on. */
  public readonly role: iam.Role;

  /** Every foundation-model ARN the role may invoke. */
  public readonly foundationModelArns: string[];

  constructor(scope: Construct, id: string, props: BedrockInvocationRoleProps) {
    super(scope, id);

    if (props.foundationModelIds.length === 0) {
      throw new Error('foundationModelIds must contain at least one model ID');
    }
    if (props.foundationModelIds.some((modelId) => modelId.includes('*'))) {
      throw new Error('Wildcards are not allowed in foundationModelIds');
    }
    const profiles = props.inferenceProfileArns ?? [];
    if (props.restrictToInferenceProfiles && profiles.length === 0) {
      throw new Error('restrictToInferenceProfiles requires at least one inference profile ARN');
    }

    const stack = Stack.of(this);
    const regions = props.modelRegions ?? [stack.region];
    const actions = ['bedrock:InvokeModel'];
    if (props.allowStreaming ?? true) {
      actions.push('bedrock:InvokeModelWithResponseStream');
    }

    this.foundationModelArns = [];
    for (const region of regions) {
      for (const modelId of props.foundationModelIds) {
        this.foundationModelArns.push(`arn:${stack.partition}:bedrock:${region}::foundation-model/${modelId}`);
      }
    }
    if (props.allowGlobalInference) {
      for (const modelId of props.foundationModelIds) {
        this.foundationModelArns.push(`arn:${stack.partition}:bedrock:::foundation-model/${modelId}`);
      }
    }

    this.role = new iam.Role(this, 'Role', {
      assumedBy: props.assumedBy,
      roleName: props.roleName,
      description: `Invokes Amazon Bedrock models: ${props.foundationModelIds.join(', ')}`,
    });

    if (profiles.length > 0) {
      this.role.addToPolicy(
        new iam.PolicyStatement({
          sid: 'InvokeThroughInferenceProfiles',
          actions,
          resources: profiles,
        }),
      );
    }

    this.role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'InvokeFoundationModels',
        actions,
        resources: this.foundationModelArns,
        conditions: props.restrictToInferenceProfiles
          ? { StringLike: { 'bedrock:InferenceProfileArn': profiles } }
          : undefined,
      }),
    );

    if (props.guardrailArns && props.guardrailArns.length > 0) {
      this.role.addToPolicy(
        new iam.PolicyStatement({
          sid: 'ApplyGuardrails',
          actions: ['bedrock:ApplyGuardrail'],
          resources: props.guardrailArns,
        }),
      );
    }

    if (props.requiredGuardrailArnPattern) {
      this.role.addToPolicy(
        new iam.PolicyStatement({
          sid: 'DenyInferenceWithoutRequiredGuardrail',
          effect: iam.Effect.DENY,
          actions: ['bedrock:InvokeModel', 'bedrock:InvokeModelWithResponseStream'],
          resources: ['*'],
          conditions: {
            ArnNotLike: { 'bedrock:GuardrailIdentifier': props.requiredGuardrailArnPattern },
          },
        }),
      );
    }
  }
}
