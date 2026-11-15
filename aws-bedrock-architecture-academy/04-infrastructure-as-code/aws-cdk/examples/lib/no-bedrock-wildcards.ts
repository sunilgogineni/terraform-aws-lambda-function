import { Annotations, IAspect, Stack } from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import { IConstruct } from 'constructs';

/**
 * Chapter 7: an Aspect that reports an error when an IAM policy in the scope allows
 * `bedrock:*`, `bedrock-agentcore:*` or `*` as an action.
 *
 * Aspects run during the preparation phase of synthesis, after every construct exists,
 * so they also see policies that grant methods added inside other constructs.
 */
export class NoBedrockWildcards implements IAspect {
  private static readonly FORBIDDEN = new Set(['*', 'bedrock:*', 'bedrock-agentcore:*']);

  public visit(node: IConstruct): void {
    if (!(node instanceof iam.CfnPolicy || node instanceof iam.CfnManagedPolicy)) {
      return;
    }
    const document = Stack.of(node).resolve(node.policyDocument);
    for (const statement of document?.Statement ?? []) {
      if (statement.Effect !== 'Allow') {
        continue;
      }
      const actions: string[] = [].concat(statement.Action ?? []);
      const bad = actions.filter((action) => NoBedrockWildcards.FORBIDDEN.has(action));
      if (bad.length > 0) {
        Annotations.of(node).addError(`Wildcard action ${bad.join(', ')} is not allowed; list the actions you need`);
      }
    }
  }
}
