output "registry_id" {
  description = "The registry ID where the registry configuration is applied"
  value       = try(module.ecr.repository_registry_id, null)
}

output "registry_scanning_configuration_id" {
  description = "The ID of the registry scanning configuration"
  value       = var.manage_registry_scanning_configuration ? "configured" : null
}

output "registry_replication_configuration_id" {
  description = "The ID of the registry replication configuration"
  value       = var.create_registry_replication_configuration ? "configured" : null
}

output "registry_policy_text" {
  description = "The registry policy text"
  value       = var.registry_policy
  sensitive   = true
}

output "pull_through_cache_rules" {
  description = "Map of pull through cache rules configured"
  value       = var.pull_through_cache_rules
}
