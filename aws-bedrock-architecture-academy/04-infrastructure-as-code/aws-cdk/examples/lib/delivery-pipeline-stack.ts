import { CfnResource, Environment, Stack, StackProps, Stage, StageProps } from 'aws-cdk-lib';
import * as codepipeline from 'aws-cdk-lib/aws-codepipeline';
import * as pipelines from 'aws-cdk-lib/pipelines';
import { Construct } from 'constructs';
import { AgentMemoryStack } from './agent-memory-stack';
import { GuardrailL1Stack } from './guardrail-l1-stack';
import { InvocationLoggingStack } from './invocation-logging-stack';

/** One deployable copy of the workload: the Bedrock stacks from chapter 9. */
export class BedrockWorkloadStage extends Stage {
  constructor(scope: Construct, id: string, props: StageProps) {
    super(scope, id, props);
    new GuardrailL1Stack(this, 'Guardrail');
    new AgentMemoryStack(this, 'AgentMemory');
    new InvocationLoggingStack(this, 'InvocationLogging');
  }
}

export interface DeliveryPipelineStackProps extends StackProps {
  /** `owner/repository` of the source repository. */
  readonly repository: string;
  /** @default 'main' */
  readonly branch?: string;
  /** ARN of an AWS CodeConnections connection to the repository host (created once, in the console). */
  readonly connectionArn: string;
  /** Target environment. Bootstrap it with `--trust <tooling account>` before the first run. */
  readonly workloadEnv: Required<Pick<Environment, 'account' | 'region'>>;
}

/**
 * Chapter 6: CDK Pipelines in a tooling account deploying into a separate workload account.
 *
 * Cross-account rules that this code relies on:
 * - the workload environment is bootstrapped with `--trust` naming the tooling account;
 * - `crossAccountKeys: true` encrypts the artifact bucket with a KMS key the target can use.
 */
export class DeliveryPipelineStack extends Stack {
  public readonly pipeline: pipelines.CodePipeline;

  constructor(scope: Construct, id: string, props: DeliveryPipelineStackProps) {
    super(scope, id, props);

    this.pipeline = new pipelines.CodePipeline(this, 'Pipeline', {
      pipelineType: codepipeline.PipelineType.V2,
      crossAccountKeys: true,
      enableKeyRotation: true,
      synth: new pipelines.ShellStep('Synth', {
        input: pipelines.CodePipelineSource.connection(props.repository, props.branch ?? 'main', {
          connectionArn: props.connectionArn,
        }),
        // Tests run before synthesis: a failing assertion stops the pipeline before any deployment.
        commands: ['npm ci', 'npx tsc', 'npx jest --ci', 'npx cdk synth'],
      }),
    });

    this.pipeline.addStage(new BedrockWorkloadStage(this, 'Workload', { env: props.workloadEnv }), {
      pre: [new pipelines.ManualApprovalStep('ApproveWorkloadChange')],
    });

    // Build the pipeline now (instead of at synthesis) so the underlying L1 can be reached.
    // cfn-lint 1.60.1 reports E3703 for the Fn::Join role ARNs that CDK Pipelines writes into
    // CloudFormation deploy actions; suppress that one rule on that one resource, with a reason.
    this.pipeline.buildPipeline();
    (this.pipeline.pipeline.node.defaultChild as CfnResource).addMetadata('cfn-lint', {
      config: { ignore_checks: ['E3703'] },
    });
  }
}
