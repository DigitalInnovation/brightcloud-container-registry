output "registry_name" {
  description = "Name of the nonprod container registry"
  value       = module.acr_registry.registry_name
}

output "registry_url" {
  description = "Login server URL of the nonprod container registry"
  value       = module.acr_registry.registry_url
}

output "registry_id" {
  description = "ID of the nonprod container registry"
  value       = module.acr_registry.registry_id
}

output "supported_environments" {
  description = "List of supported environments in nonprod registry"
  value       = ["pr", "dev", "perf"]
}

output "environment_scopes" {
  description = "Environment scope configurations"
  value       = module.acr_registry.environment_scopes
}

output "private_endpoint" {
  description = "Private endpoint configuration"
  value       = module.acr_network.private_endpoint
}

output "team_access_summary" {
  description = "Summary of team access configurations"
  value       = module.acr_rbac.role_assignments
}