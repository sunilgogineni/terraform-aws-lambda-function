import { App, Stack } from 'aws-cdk-lib';
import { Capture, Match, Template } from 'aws-cdk-lib/assertions';
import * as iam from 'aws-cdk-lib/aws-iam';
import { ContentGuardrail, FilterStrength } from '../lib/content-guardrail';

// Fine-grained assertions on a synthesized template. Nothing is deployed; no credentials are used.

function newStack(): Stack {
  return new Stack(new App(), 'TestStack', { env: { account: '111122223333', region: 'us-east-1' } });
}

describe('ContentGuardrail', () => {
  test('defaults: harmful-content filters, prompt attacks, PII anonymization, one published version', () => {
    const stack = newStack();
    new ContentGuardrail(stack, 'Guardrail');
    const template = Template.fromStack(stack);

    template.resourceCountIs('AWS::Bedrock::Guardrail', 1);
    template.resourceCountIs('AWS::Bedrock::GuardrailVersion', 1);
    template.hasResourceProperties('AWS::Bedrock::Guardrail', {
      ContentPolicyConfig: {
        FiltersConfig: Match.arrayWith([
          { Type: 'HATE', InputStrength: 'HIGH', OutputStrength: 'HIGH' },
          { Type: 'PROMPT_ATTACK', InputStrength: 'HIGH', OutputStrength: 'NONE' },
        ]),
      },
      SensitiveInformationPolicyConfig: {
        PiiEntitiesConfig: [
          { Type: 'EMAIL', Action: 'ANONYMIZE' },
          { Type: 'PHONE', Action: 'ANONYMIZE' },
        ],
      },
      TopicPolicyConfig: Match.absent(), // no topics were requested
      KmsKeyArn: Match.absent(), // AWS managed key by default
    });
  });

  test('the version points at this guardrail (Capture)', () => {
    const stack = newStack();
    new ContentGuardrail(stack, 'Guardrail');
    const template = Template.fromStack(stack);

    const identifier = new Capture();
    template.hasResourceProperties('AWS::Bedrock::GuardrailVersion', { GuardrailIdentifier: identifier });
    const guardrailLogicalId = template.getResourceId('AWS::Bedrock::Guardrail');
    expect(identifier.asObject()).toEqual({ 'Fn::GetAtt': [guardrailLogicalId, 'GuardrailId'] });
  });

  test('changing the policy changes the version description, so a new version is published', () => {
    const description = (strength: FilterStrength): string => {
      const stack = newStack();
      new ContentGuardrail(stack, 'Guardrail', { harmfulContentStrength: strength });
      const capture = new Capture();
      Template.fromStack(stack).hasResourceProperties('AWS::Bedrock::GuardrailVersion', { Description: capture });
      return capture.asString();
    };
    expect(description(FilterStrength.HIGH)).toEqual(description(FilterStrength.HIGH));
    expect(description(FilterStrength.HIGH)).not.toEqual(description(FilterStrength.MEDIUM));
  });

  test('denied topics are rendered as DENY topics', () => {
    const stack = newStack();
    new ContentGuardrail(stack, 'Guardrail', {
      deniedTopics: [{ name: 'InvestmentAdvice', definition: 'Recommendations about specific securities.' }],
    });
    Template.fromStack(stack).hasResourceProperties('AWS::Bedrock::Guardrail', {
      TopicPolicyConfig: { TopicsConfig: [Match.objectLike({ Name: 'InvestmentAdvice', Type: 'DENY' })] },
    });
  });

  test('grantApply scopes bedrock:ApplyGuardrail to this guardrail only', () => {
    const stack = newStack();
    const guardrail = new ContentGuardrail(stack, 'Guardrail');
    const role = new iam.Role(stack, 'AppRole', { assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com') });
    guardrail.grantApply(role);

    const template = Template.fromStack(stack);
    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: [
          {
            Action: 'bedrock:ApplyGuardrail',
            Effect: 'Allow',
            Resource: { 'Fn::GetAtt': [template.getResourceId('AWS::Bedrock::Guardrail'), 'GuardrailArn'] },
          },
        ],
      },
    });
  });

  test('validation fails at synth time, not during deployment', () => {
    const stack = newStack();
    expect(() => new ContentGuardrail(stack, 'BadName', { guardrailName: 'has spaces' })).toThrow(/guardrailName/);
    const topics = Array.from({ length: 31 }, (_, i) => ({ name: `Topic${i}`, definition: 'x' }));
    expect(() => new ContentGuardrail(stack, 'TooMany', { deniedTopics: topics })).toThrow(/At most 30/);
    expect(
      () =>
        new ContentGuardrail(stack, 'Empty', {
          harmfulContentStrength: FilterStrength.NONE,
          blockPromptAttacks: false,
          anonymizePiiTypes: [],
        }),
    ).toThrow(/no active policy/);
  });

  test('logical IDs are part of the public contract (renaming replaces the guardrail)', () => {
    const stack = newStack();
    const guardrail = new ContentGuardrail(stack, 'Guardrail');
    // If this assertion fails after a refactor, the next deployment would replace the guardrail
    // and its versions. Treat that as a breaking change (major version), or keep the IDs.
    expect(stack.resolve(guardrail.cfnGuardrail.logicalId)).toBe('Guardrail91D61981');
  });
});
