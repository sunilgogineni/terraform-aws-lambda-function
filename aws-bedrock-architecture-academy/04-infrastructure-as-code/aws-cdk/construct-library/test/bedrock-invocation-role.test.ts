import { App, Stack } from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import * as iam from 'aws-cdk-lib/aws-iam';
import { BedrockInvocationRole } from '../lib';

// Unit tests synthesize a template in memory. Nothing is deployed and no credentials are used.

function synth(configure: (stack: Stack) => void): Template {
  const app = new App();
  const stack = new Stack(app, 'TestStack', { env: { account: '111122223333', region: 'us-east-1' } });
  configure(stack);
  return Template.fromStack(stack);
}

const lambdaPrincipal = () => new iam.ServicePrincipal('lambda.amazonaws.com');

describe('BedrockInvocationRole', () => {
  test('grants named models in named Regions, with streaming by default', () => {
    const template = synth((stack) => {
      new BedrockInvocationRole(stack, 'Invoke', {
        assumedBy: lambdaPrincipal(),
        foundationModelIds: ['example.model-a-v1:0'],
        modelRegions: ['us-east-1', 'us-west-2'],
      });
    });

    template.resourceCountIs('AWS::IAM::Role', 1);
    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: [
          {
            Sid: 'InvokeFoundationModels',
            Effect: 'Allow',
            Action: ['bedrock:InvokeModel', 'bedrock:InvokeModelWithResponseStream'],
            Resource: Match.arrayWith([Match.objectLike({ 'Fn::Join': Match.anyValue() })]),
          },
        ],
      },
    });
  });

  test('never grants a wildcard resource for an Allow statement', () => {
    const template = synth((stack) => {
      new BedrockInvocationRole(stack, 'Invoke', {
        assumedBy: lambdaPrincipal(),
        foundationModelIds: ['example.model-a-v1:0'],
      });
    });

    const policies = template.findResources('AWS::IAM::Policy');
    for (const policy of Object.values(policies)) {
      for (const statement of policy.Properties.PolicyDocument.Statement) {
        if (statement.Effect === 'Allow') {
          expect(statement.Resource).not.toBe('*');
        }
      }
    }
  });

  test('streaming can be switched off', () => {
    const template = synth((stack) => {
      new BedrockInvocationRole(stack, 'Invoke', {
        assumedBy: lambdaPrincipal(),
        foundationModelIds: ['example.model-a-v1:0'],
        allowStreaming: false,
      });
    });

    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: { Statement: [Match.objectLike({ Action: 'bedrock:InvokeModel' })] },
    });
  });

  test('global inference adds the Region-less model ARN', () => {
    const app = new App();
    const stack = new Stack(app, 'TestStack', { env: { account: '111122223333', region: 'us-east-1' } });
    const construct = new BedrockInvocationRole(stack, 'Invoke', {
      assumedBy: lambdaPrincipal(),
      foundationModelIds: ['example.model-a-v1:0'],
      modelRegions: ['us-east-1'],
      allowGlobalInference: true,
      inferenceProfileArns: ['arn:aws:bedrock:us-east-1:111122223333:inference-profile/global.example.model-a-v1:0'],
    });

    expect(construct.foundationModelArns).toHaveLength(2);
    expect(stack.resolve(construct.foundationModelArns[1])).toEqual({
      'Fn::Join': ['', ['arn:', { Ref: 'AWS::Partition' }, ':bedrock:::foundation-model/example.model-a-v1:0']],
    });
  });

  test('restricting to inference profiles adds the condition key', () => {
    const profile = 'arn:aws:bedrock:us-east-1:111122223333:inference-profile/us.example.model-a-v1:0';
    const template = synth((stack) => {
      new BedrockInvocationRole(stack, 'Invoke', {
        assumedBy: lambdaPrincipal(),
        foundationModelIds: ['example.model-a-v1:0'],
        inferenceProfileArns: [profile],
        restrictToInferenceProfiles: true,
      });
    });

    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({
            Sid: 'InvokeFoundationModels',
            Condition: { StringLike: { 'bedrock:InferenceProfileArn': [profile] } },
          }),
        ]),
      },
    });
  });

  test('a required guardrail produces an explicit deny and an ApplyGuardrail grant', () => {
    const guardrail = 'arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123';
    const template = synth((stack) => {
      new BedrockInvocationRole(stack, 'Invoke', {
        assumedBy: lambdaPrincipal(),
        foundationModelIds: ['example.model-a-v1:0'],
        guardrailArns: [guardrail],
        requiredGuardrailArnPattern: `${guardrail}:*`,
      });
    });

    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({ Sid: 'ApplyGuardrails', Action: 'bedrock:ApplyGuardrail', Resource: guardrail }),
          Match.objectLike({
            Sid: 'DenyInferenceWithoutRequiredGuardrail',
            Effect: 'Deny',
            Condition: { ArnNotLike: { 'bedrock:GuardrailIdentifier': `${guardrail}:*` } },
          }),
        ]),
      },
    });
  });

  test('rejects wildcards and empty model lists', () => {
    const app = new App();
    const stack = new Stack(app, 'TestStack');
    expect(
      () => new BedrockInvocationRole(stack, 'A', { assumedBy: lambdaPrincipal(), foundationModelIds: ['*'] }),
    ).toThrow(/Wildcards/);
    expect(
      () => new BedrockInvocationRole(stack, 'B', { assumedBy: lambdaPrincipal(), foundationModelIds: [] }),
    ).toThrow(/at least one/);
  });
});
