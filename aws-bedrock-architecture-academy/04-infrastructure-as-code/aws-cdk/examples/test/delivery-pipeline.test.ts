import { App, DefaultStackSynthesizer, Stack } from 'aws-cdk-lib';
import { Capture, Match, Template } from 'aws-cdk-lib/assertions';
import * as sns from 'aws-cdk-lib/aws-sns';
import { DeliveryPipelineStack } from '../lib/delivery-pipeline-stack';

// Chapter 6: the bootstrap contract, as it appears in synthesized templates.

const TOOLING = '111122223333';
const WORKLOAD = '444455556666';

describe('DeliveryPipelineStack (CDK Pipelines, cross-account)', () => {
  const stack = new DeliveryPipelineStack(new App(), 'Pipeline', {
    env: { account: TOOLING, region: 'us-east-1' },
    repository: 'example-org/bedrock-platform',
    connectionArn: `arn:aws:codeconnections:us-east-1:${TOOLING}:connection/00000000-0000-0000-0000-000000000000`,
    workloadEnv: { account: WORKLOAD, region: 'us-east-1' },
  });
  const template = Template.fromStack(stack);

  test('cross-account delivery encrypts pipeline artifacts with a customer managed key', () => {
    template.resourceCountIs('AWS::KMS::Key', 1);
    template.hasResourceProperties('AWS::KMS::Key', { EnableKeyRotation: true });
  });

  test('deploy actions assume the bootstrap roles in the workload account', () => {
    const actionRole = new Capture(Match.stringLikeRegexp('deploy-role'));
    const executionRole = new Capture(Match.stringLikeRegexp('cfn-exec-role'));
    template.hasResourceProperties('AWS::CodePipeline::Pipeline', {
      Stages: Match.arrayWith([
        Match.objectLike({
          Name: 'Workload',
          Actions: Match.arrayWith([
            Match.objectLike({
              Name: 'Guardrail.Prepare',
              RoleArn: { 'Fn::Join': ['', Match.arrayWith([actionRole])] },
              Configuration: Match.objectLike({
                ActionMode: 'CHANGE_SET_REPLACE',
                RoleArn: { 'Fn::Join': ['', Match.arrayWith([executionRole])] },
              }),
            }),
          ]),
        }),
      ]),
    });
    expect(actionRole.asString()).toBe(`:iam::${WORKLOAD}:role/cdk-hnb659fds-deploy-role-${WORKLOAD}-us-east-1`);
    expect(executionRole.asString()).toBe(`:iam::${WORKLOAD}:role/cdk-hnb659fds-cfn-exec-role-${WORKLOAD}-us-east-1`);
  });

  test('a manual approval runs before the workload stage deploys', () => {
    template.hasResourceProperties('AWS::CodePipeline::Pipeline', {
      Stages: Match.arrayWith([
        Match.objectLike({
          Name: 'Workload',
          Actions: Match.arrayWith([
            Match.objectLike({ Name: 'ApproveWorkloadChange', ActionTypeId: Match.objectLike({ Category: 'Approval' }) }),
          ]),
        }),
      ]),
    });
  });
});

describe('DefaultStackSynthesizer and the bootstrap version check', () => {
  function templateFor(synthesizer?: DefaultStackSynthesizer): Template {
    const stack = new Stack(new App(), 'Probe', { synthesizer });
    new sns.Topic(stack, 'Topic');
    return Template.fromStack(stack);
  }

  test('every stack reads the bootstrap version from SSM and checks it with a Rule', () => {
    const json = templateFor().toJSON();
    expect(json.Parameters.BootstrapVersion.Default).toBe('/cdk-bootstrap/hnb659fds/version');
    expect(json.Rules.CheckBootstrapVersion).toBeDefined();
  });

  test('a custom qualifier must match the one used with cdk bootstrap --qualifier', () => {
    const json = templateFor(new DefaultStackSynthesizer({ qualifier: 'acad1' })).toJSON();
    expect(json.Parameters.BootstrapVersion.Default).toBe('/cdk-bootstrap/acad1/version');
  });
});
