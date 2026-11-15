import { App } from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import { AgentMemoryStack } from '../lib/agent-memory-stack';
import { GuardrailL1Stack } from '../lib/guardrail-l1-stack';
import { InvocationLoggingStack } from '../lib/invocation-logging-stack';

// Chapter 9: what each level of construct puts into the template.

describe('GuardrailL1Stack (L1 CfnGuardrail)', () => {
  const template = Template.fromStack(new GuardrailL1Stack(new App(), 'Guardrail'));

  test('renders the CloudFormation properties one-to-one', () => {
    template.hasResourceProperties('AWS::Bedrock::Guardrail', {
      Name: 'Guardrail-guardrail',
      BlockedInputMessaging: Match.anyValue(),
      BlockedOutputsMessaging: Match.anyValue(),
      TopicPolicyConfig: { TopicsConfig: [Match.objectLike({ Name: 'InvestmentAdvice', Type: 'DENY' })] },
      WordPolicyConfig: { ManagedWordListsConfig: [{ Type: 'PROFANITY' }] },
    });
  });

  test('publishes one version of that guardrail', () => {
    template.hasResourceProperties('AWS::Bedrock::GuardrailVersion', {
      GuardrailIdentifier: { 'Fn::GetAtt': [template.getResourceId('AWS::Bedrock::Guardrail'), 'GuardrailId'] },
    });
  });
});

describe('AgentMemoryStack (stable L2 Memory)', () => {
  const template = Template.fromStack(new AgentMemoryStack(new App(), 'Memory'));

  test('sets expiry in days and the two built-in strategies', () => {
    template.hasResourceProperties('AWS::BedrockAgentCore::Memory', {
      EventExpiryDuration: 30,
      MemoryStrategies: Match.arrayWith([
        { SemanticMemoryStrategy: Match.objectLike({ Name: Match.anyValue() }) },
        { SummaryMemoryStrategy: Match.objectLike({ Name: Match.anyValue() }) },
      ]),
    });
  });

  test('the L2 adds an execution role trusted only for this account', () => {
    template.hasResourceProperties('AWS::IAM::Role', {
      AssumeRolePolicyDocument: {
        Statement: [
          Match.objectLike({
            Principal: { Service: 'bedrock-agentcore.amazonaws.com' },
            Condition: Match.objectLike({ StringEquals: { 'aws:SourceAccount': { Ref: 'AWS::AccountId' } } }),
          }),
        ],
      },
    });
  });

  test('grants are scoped to the memory ARN', () => {
    const memoryArn = { 'Fn::GetAtt': [template.getResourceId('AWS::BedrockAgentCore::Memory'), 'MemoryArn'] };
    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({ Action: 'bedrock-agentcore:CreateEvent', Resource: memoryArn }),
          Match.objectLike({ Action: Match.arrayWith(['bedrock-agentcore:RetrieveMemoryRecords']), Resource: memoryArn }),
        ]),
      },
    });
  });
});

describe('InvocationLoggingStack (gap filled with AwsCustomResource)', () => {
  const template = Template.fromStack(new InvocationLoggingStack(new App(), 'Logging'));

  test('calls PutModelInvocationLoggingConfiguration on create and Delete... on delete', () => {
    template.hasResourceProperties('Custom::AWS', {
      Create: { 'Fn::Join': ['', Match.arrayWith([Match.stringLikeRegexp('"action":"PutModelInvocationLoggingConfiguration"')])] },
      Delete: Match.serializedJson({ service: 'bedrock', action: 'DeleteModelInvocationLoggingConfiguration' }),
    });
  });

  test('the bucket policy lets only Bedrock in this account write log objects', () => {
    template.hasResourceProperties('AWS::S3::BucketPolicy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({
            Sid: 'AmazonBedrockLogsWrite',
            Principal: { Service: 'bedrock.amazonaws.com' },
            Action: 's3:PutObject',
            Condition: Match.objectLike({ StringEquals: { 'aws:SourceAccount': { Ref: 'AWS::AccountId' } } }),
          }),
        ]),
      },
    });
  });
});
