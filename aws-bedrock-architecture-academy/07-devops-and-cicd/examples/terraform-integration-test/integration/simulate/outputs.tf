output "all_allowed" {
  description = "True when every simulated request is allowed."
  value       = data.aws_iam_principal_policy_simulation.this.all_allowed
}

output "decisions" {
  description = "Distinct decisions returned: allowed, explicitDeny or implicitDeny."
  value       = toset([for r in data.aws_iam_principal_policy_simulation.this.results : r.decision])
}
