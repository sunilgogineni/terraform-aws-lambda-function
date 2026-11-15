# Backend settings for the prod environment (partial configuration).
# Used as: terraform init -reconfigure -backend-config=env/prod/backend.hcl
#
# The state bucket lives in the prod account itself, so credentials for one
# environment cannot read or overwrite another environment's state.
# Placeholder values: replace the bucket name and the KMS key ARN.

bucket     = "example-tfstate-999999999999-us-east-1"
key        = "chat/bedrock-invocation-role/terraform.tfstate"
region     = "us-east-1"
kms_key_id = "arn:aws:kms:us-east-1:999999999999:key/1234abcd-12ab-34cd-56ef-1234567890ab"

# Refuse to touch state with credentials for any other account.
allowed_account_ids = ["999999999999"]

# Role in the prod account that may read and write this state object only.
assume_role = {
  role_arn     = "arn:aws:iam::999999999999:role/example-terraform-state-prod"
  session_name = "terraform-state-prod"
}
