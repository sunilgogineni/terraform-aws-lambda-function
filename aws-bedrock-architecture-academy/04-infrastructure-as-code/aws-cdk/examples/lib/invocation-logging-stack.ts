import { RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

/**
 * Chapter 9, gap example: model invocation logging has no CloudFormation resource type,
 * so a custom resource calls the Bedrock control-plane API during deployment.
 *
 * The bucket policy follows "Set up an Amazon S3 destination" in the Bedrock user guide.
 * Invocation logging is an account-and-Region setting: deploy this once per account and
 * Region, never from two stacks.
 */
export class InvocationLoggingStack extends Stack {
  public readonly bucket: s3.Bucket;

  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    const prefix = 'bedrock';
    this.bucket = new s3.Bucket(this, 'InvocationLogs', {
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED, // ACLs disabled, as the guide requires
      enforceSSL: true,
      versioned: true,
      removalPolicy: RemovalPolicy.RETAIN, // prompts and responses are evidence; keep them
    });

    this.bucket.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'AmazonBedrockLogsWrite',
        principals: [new iam.ServicePrincipal('bedrock.amazonaws.com')],
        actions: ['s3:PutObject'],
        resources: [this.bucket.arnForObjects(`${prefix}/AWSLogs/${this.account}/BedrockModelInvocationLogs/*`)],
        conditions: {
          StringEquals: { 'aws:SourceAccount': this.account },
          ArnLike: { 'aws:SourceArn': `arn:${this.partition}:bedrock:${this.region}:${this.account}:*` },
        },
      }),
    );

    const put: cr.AwsSdkCall = {
      service: 'bedrock',
      action: 'PutModelInvocationLoggingConfiguration',
      parameters: {
        loggingConfig: {
          s3Config: { bucketName: this.bucket.bucketName, keyPrefix: prefix },
          textDataDeliveryEnabled: true,
          imageDataDeliveryEnabled: false,
          embeddingDataDeliveryEnabled: false,
        },
      },
      physicalResourceId: cr.PhysicalResourceId.of(`bedrock-invocation-logging-${this.region}`),
    };

    const logging = new cr.AwsCustomResource(this, 'ModelInvocationLogging', {
      onCreate: put,
      onUpdate: put,
      onDelete: { service: 'bedrock', action: 'DeleteModelInvocationLoggingConfiguration' },
      // The logging configuration is account-level, so there is no resource ARN to scope to.
      policy: cr.AwsCustomResourcePolicy.fromStatements([
        new iam.PolicyStatement({
          actions: ['bedrock:PutModelInvocationLoggingConfiguration', 'bedrock:DeleteModelInvocationLoggingConfiguration'],
          resources: ['*'],
        }),
      ]),
      // Use the SDK v3 that ships in the Lambda Node.js runtime. Set true only if you need an
      // API newer than that SDK (the function then downloads the SDK from npm on every run).
      installLatestAwsSdk: false,
    });
    // Create the bucket and its policy first, so Bedrock can write as soon as logging is on.
    logging.node.addDependency(this.bucket);
  }
}
