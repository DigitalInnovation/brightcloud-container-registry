output "registry_name" {
  description = "Name of the sandbox container registry"
  value       = module.acr_registry.registry_name
}

output "registry_url" {
  description = "Login server URL of the sandbox container registry"
  value       = module.acr_registry.registry_url
}

output "registry_id" {
  description = "ID of the sandbox container registry"
  value       = module.acr_registry.registry_id
}

output "supported_environments" {
  description = "List of supported environments in sandbox registry"
  value       = ["sandbox"]
}

output "environment_scopes" {
  description = "Environment scope configurations"
  value       = module.acr_registry.environment_scopes
}

output "private_endpoint" {
  description = "Private endpoint configuration (typically null for sandbox)"
  value       = module.acr_network.private_endpoint
}

output "team_access_summary" {
  description = "Summary of team access configurations"
  value       = module.acr_rbac.role_assignments
}