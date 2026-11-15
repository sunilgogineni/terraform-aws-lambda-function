import { CfnOutput, Duration, Stack, StackProps } from 'aws-cdk-lib';
import * as agentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

/**
 * Chapter 9, example 2: AgentCore Memory with the stable L2 construct from `aws-cdk-lib`.
 *
 * The L2 fills in what the L1 would make you write by hand: an execution role, strategy
 * names, the expiry in days, and `grant*` methods that scope IAM to this memory's ARN.
 */
export class AgentMemoryStack extends Stack {
  public readonly memory: agentcore.Memory;
  /** Stand-in for the role your agent runs as (for example an AgentCore Runtime execution role). */
  public readonly agentRole: iam.Role;

  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    this.memory = new agentcore.Memory(this, 'ConversationMemory', {
      description: 'Short-term events for 30 days plus semantic and summary long-term records',
      expirationDuration: Duration.days(30),
      memoryStrategies: [
        agentcore.MemoryStrategy.usingBuiltInSemantic(),
        agentcore.MemoryStrategy.usingBuiltInSummarization(),
      ],
    });

    this.agentRole = new iam.Role(this, 'AgentRole', {
      assumedBy: new iam.ServicePrincipal('bedrock-agentcore.amazonaws.com'),
      description: 'Example agent identity: may write events and read long-term memory records',
    });
    this.memory.grantWrite(this.agentRole);
    this.memory.grantReadLongTermMemory(this.agentRole);

    new CfnOutput(this, 'MemoryId', { value: this.memory.memoryId });
  }
}
