import { App, Aspects, Stack, Validations } from 'aws-cdk-lib';
import { Annotations, Match, Template } from 'aws-cdk-lib/assertions';
import * as iam from 'aws-cdk-lib/aws-iam';
import { AwsSolutionsChecks } from 'cdk-nag';
import { ContentGuardrail } from '../lib/content-guardrail';
import { GuardrailL1Stack } from '../lib/guardrail-l1-stack';
import { NoBedrockWildcards } from '../lib/no-bedrock-wildcards';

// Chapter 7: testing an Aspect, running cdk-nag v3 in a unit test, and a snapshot test.

/** A small "application" stack: a role that may apply one guardrail. */
function consumerStack(app: App, grantWildcard: boolean): Stack {
  const stack = new Stack(app, 'Consumer', { env: { account: '111122223333', region: 'us-east-1' } });
  const guardrail = new ContentGuardrail(stack, 'Guardrail');
  const role = new iam.Role(stack, 'AppRole', { assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com') });
  guardrail.grantApply(role);
  if (grantWildcard) {
    role.addToPolicy(new iam.PolicyStatement({ actions: ['bedrock:*'], resources: ['*'] }));
  }
  return stack;
}

describe('Aspect: NoBedrockWildcards', () => {
  test('reports an error annotation on the offending policy', () => {
    const app = new App();
    const stack = consumerStack(app, true);
    Aspects.of(stack).add(new NoBedrockWildcards());

    Annotations.fromStack(stack).hasError(
      '/Consumer/AppRole/DefaultPolicy/Resource',
      Match.stringLikeRegexp('Wildcard action bedrock:\\*'),
    );
  });

  test('stays quiet when every grant is scoped', () => {
    const app = new App();
    const stack = consumerStack(app, false);
    Aspects.of(stack).add(new NoBedrockWildcards());

    Annotations.fromStack(stack).hasNoError('*', Match.anyValue());
  });
});

describe('cdk-nag v3 (AwsSolutions pack) as a policy-validation plugin', () => {
  // cdk-nag 3.x registers with Validations.of(app).addPlugins(); a violation interrupts
  // synthesis, so the test asserts on the thrown report instead of on annotations.
  test('a scoped grant passes the AwsSolutions checks', () => {
    const app = new App();
    const stack = consumerStack(app, false);
    Validations.of(app).addPlugins(new AwsSolutionsChecks(app));

    expect(() => Template.fromStack(stack)).not.toThrow();
  });

  test('a wildcard grant fails synthesis with AwsSolutions-IAM5', () => {
    const app = new App();
    const stack = consumerStack(app, true);
    Validations.of(app).addPlugins(new AwsSolutionsChecks(app));

    expect(() => Template.fromStack(stack)).toThrow(/AwsSolutions-IAM5/);
  });

  test('an acknowledged finding, with a reason, no longer fails', () => {
    const app = new App();
    const stack = consumerStack(app, true);
    Validations.of(stack).acknowledge(
      { id: 'AwsSolutions-IAM5[Action::bedrock:*]', reason: 'Test fixture: demonstrates an acknowledgement.' },
      { id: 'AwsSolutions-IAM5[Resource::*]', reason: 'Test fixture: demonstrates an acknowledgement.' },
    );
    Validations.of(app).addPlugins(new AwsSolutionsChecks(app));

    expect(() => Template.fromStack(stack)).not.toThrow();
  });
});

describe('snapshot', () => {
  // A snapshot catches *any* change to the template, including ones caused by upgrading
  // aws-cdk-lib. Review the diff, then accept it with `npx jest -u` if it is intended.
  test('GuardrailL1Stack template is unchanged', () => {
    const stack = new GuardrailL1Stack(new App(), 'Snapshot');
    expect(Template.fromStack(stack).toJSON()).toMatchSnapshot();
  });
});
