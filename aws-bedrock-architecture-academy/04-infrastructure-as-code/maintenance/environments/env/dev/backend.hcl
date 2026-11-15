# Backend settings for the dev environment (partial configuration).
# Used as: terraform init -reconfigure -backend-config=env/dev/backend.hcl
#
# The state bucket lives in the dev account itself, so credentials for one
# environment cannot read or overwrite another environment's state.
# Placeholder values: replace the bucket name and the KMS key ARN.

bucket     = "example-tfstate-111122223333-us-east-1"
key        = "chat/bedrock-invocation-role/terraform.tfstate"
region     = "us-east-1"
kms_key_id = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"

# Role in the dev account that may read and write this state object only.
assume_role = {
  role_arn     = "arn:aws:iam::111122223333:role/example-terraform-state-dev"
  session_name = "terraform-state-dev"
}
