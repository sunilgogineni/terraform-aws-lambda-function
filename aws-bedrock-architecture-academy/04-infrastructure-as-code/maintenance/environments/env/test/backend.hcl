# Backend settings for the test environment (partial configuration).
# Used as: terraform init -reconfigure -backend-config=env/test/backend.hcl
#
# The state bucket lives in the test account itself, so credentials for one
# environment cannot read or overwrite another environment's state.
# Placeholder values: replace the bucket name and the KMS key ARN.

bucket     = "example-tfstate-444455556666-us-east-1"
key        = "chat/bedrock-invocation-role/terraform.tfstate"
region     = "us-east-1"
kms_key_id = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"

# Refuse to touch state with credentials for any other account.
allowed_account_ids = ["444455556666"]

# Role in the test account that may read and write this state object only.
assume_role = {
  role_arn     = "arn:aws:iam::444455556666:role/example-terraform-state-test"
  session_name = "terraform-state-test"
}
