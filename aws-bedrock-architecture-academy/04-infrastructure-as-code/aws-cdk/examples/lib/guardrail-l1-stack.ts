import { CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import * as bedrock from 'aws-cdk-lib/aws-bedrock';
import { Construct } from 'constructs';

/**
 * Chapter 9, example 1: an Amazon Bedrock guardrail written directly with the L1 constructs.
 *
 * `aws-cdk-lib/aws-bedrock` has no stable L2 for guardrails, so ADR-012 says: use the L1.
 * Property names mirror `AWS::Bedrock::Guardrail` one-to-one; enum values (filter types,
 * strengths, PII types, actions) come from the CreateGuardrail API model.
 */
export class GuardrailL1Stack extends Stack {
  public readonly guardrail: bedrock.CfnGuardrail;
  public readonly guardrailVersion: bedrock.CfnGuardrailVersion;

  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    this.guardrail = new bedrock.CfnGuardrail(this, 'SupportGuardrail', {
      // Name: 1-50 characters, [0-9a-zA-Z-_]. Deriving it from the stack name keeps two copies
      // of the stack (for example a pipeline stage and a sandbox) from colliding in one account.
      name: `${this.stackName.slice(0, 40)}-guardrail`,
      description: 'Blocks harmful content and prompt attacks; anonymizes e-mail addresses and phone numbers',
      blockedInputMessaging: 'Sorry, I cannot help with that request.',
      blockedOutputsMessaging: 'Sorry, I cannot share that response.',
      contentPolicyConfig: {
        filtersConfig: [
          { type: 'SEXUAL', inputStrength: 'HIGH', outputStrength: 'HIGH' },
          { type: 'VIOLENCE', inputStrength: 'HIGH', outputStrength: 'HIGH' },
          { type: 'HATE', inputStrength: 'HIGH', outputStrength: 'HIGH' },
          { type: 'INSULTS', inputStrength: 'HIGH', outputStrength: 'HIGH' },
          { type: 'MISCONDUCT', inputStrength: 'HIGH', outputStrength: 'HIGH' },
          { type: 'PROMPT_ATTACK', inputStrength: 'HIGH', outputStrength: 'NONE' },
        ],
      },
      topicPolicyConfig: {
        topicsConfig: [
          {
            name: 'InvestmentAdvice',
            type: 'DENY',
            definition: 'Recommendations to buy, sell or hold specific financial products or securities.',
            examples: ['Which stock should I buy this week?'],
          },
        ],
      },
      sensitiveInformationPolicyConfig: {
        piiEntitiesConfig: [
          { type: 'EMAIL', action: 'ANONYMIZE' },
          { type: 'PHONE', action: 'ANONYMIZE' },
        ],
      },
      wordPolicyConfig: {
        managedWordListsConfig: [{ type: 'PROFANITY' }],
      },
    });

    // A version is an immutable snapshot of the guardrail's working draft. Description and
    // GuardrailIdentifier are create-only: change the description to publish a new version.
    this.guardrailVersion = new bedrock.CfnGuardrailVersion(this, 'SupportGuardrailVersion', {
      guardrailIdentifier: this.guardrail.attrGuardrailId,
      description: 'Release 1',
    });

    new CfnOutput(this, 'GuardrailId', { value: this.guardrail.attrGuardrailId });
    new CfnOutput(this, 'GuardrailVersionNumber', { value: this.guardrailVersion.attrVersion });
  }
}
