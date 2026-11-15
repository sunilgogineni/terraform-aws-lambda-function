output "endpoint_ids" {
  description = "Map of service suffix to VPC endpoint ID, for aws:SourceVpce conditions in resource policies."
  value       = { for s, ep in aws_vpc_endpoint.this : s => ep.id }
}

output "endpoint_dns_entries" {
  description = "Map of service suffix to the endpoint's DNS entries. Use these names when private DNS is off."
  value       = { for s, ep in aws_vpc_endpoint.this : s => ep.dns_entry }
}

output "endpoint_network_interface_ids" {
  description = "Map of service suffix to the endpoint network interface IDs (one per subnet)."
  value       = { for s, ep in aws_vpc_endpoint.this : s => ep.network_interface_ids }
}

output "security_group_id" {
  description = "ID of the security group attached to every endpoint."
  value       = aws_security_group.endpoints.id
}

output "service_names" {
  description = "Map of service suffix to the full endpoint service name, for example com.amazonaws.us-east-1.bedrock-runtime."
  value       = local.service_names
}

output "endpoint_policies" {
  description = "Map of service suffix to the endpoint policy JSON this module attaches, or null where the AWS default full-access policy applies."
  value       = local.endpoint_policies
}
