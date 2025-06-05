# Outputs for Complete Example

# Registry Information
output "registry_id" {
  description = "The ID of the Azure Container Registry"
  value       = module.acr_registry.registry_id
}

output "registry_name" {
  description = "The name of the Azure Container Registry"
  value       = module.acr_registry.registry_name
}

output "registry_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = module.acr_registry.login_server
}

output "registry_fqdn" {
  description = "The FQDN of the Azure Container Registry"
  value       = module.acr_registry.fqdn
}

# Authentication Information
output "registry_admin_username" {
  description = "The admin username for the Azure Container Registry (if admin is enabled)"
  value       = module.acr_registry.admin_username
  sensitive   = true
}

output "registry_admin_password" {
  description = "The admin password for the Azure Container Registry (if admin is enabled)"
  value       = module.acr_registry.admin_password
  sensitive   = true
}

# Network Information
output "private_endpoint_id" {
  description = "The ID of the private endpoint for the registry"
  value       = module.acr_network.private_endpoint_id
}

output "private_endpoint_fqdn" {
  description = "The private FQDN of the registry"
  value       = module.acr_network.private_endpoint_fqdn
}

# RBAC Information
output "scope_maps" {
  description = "The created scope maps for team-based access"
  value       = module.acr_rbac.scope_maps
  sensitive   = true
}

output "tokens" {
  description = "The created tokens for team access"
  value       = module.acr_rbac.tokens
  sensitive   = true
}

# Monitoring Information
output "diagnostic_setting_id" {
  description = "The ID of the diagnostic setting for the registry"
  value       = module.acr_monitoring.diagnostic_setting_id
}

output "alert_rules" {
  description = "The created alert rules for the registry"
  value       = module.acr_monitoring.alert_rules
}

# Security Information
output "managed_identity_id" {
  description = "The ID of the managed identity used for encryption"
  value       = azurerm_user_assigned_identity.acr.id
}

output "encryption_key_id" {
  description = "The ID of the encryption key used for the registry"
  value       = azurerm_key_vault_key.acr_encryption.id
  sensitive   = true
}

# Resource Group Information
output "resource_group_name" {
  description = "The name of the resource group containing all resources"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "The ID of the resource group containing all resources"
  value       = azurerm_resource_group.main.id
}

# Team Access Information
output "team_repository_patterns" {
  description = "Repository patterns for each team"
  value = {
    for team_name, team_config in var.teams : team_name => [
      for env in team_config.environments : "${env}/${team_name}/*"
    ]
  }
}

# Usage Examples
output "docker_commands" {
  description = "Example Docker commands for using the registry"
  value = {
    login = "az acr login --name ${module.acr_registry.registry_name}"
    build_and_push = [
      "docker build -t ${module.acr_registry.login_server}/dev/my-team/my-app:v1.0.0 .",
      "docker push ${module.acr_registry.login_server}/dev/my-team/my-app:v1.0.0"
    ]
    pull = "docker pull ${module.acr_registry.login_server}/dev/my-team/my-app:v1.0.0"
  }
}

# Cost Information
output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost in USD (Premium SKU with geo-replication)"
  value = {
    base_registry = "165.00"  # Premium SKU base cost
    geo_replication = "50.00" # Per additional region
    storage_gb = "0.10"       # Per GB per month
    total_estimate = "265.00" # Base + 2 geo regions
    note = "Actual costs depend on usage, storage, and data transfer"
  }
}

# Security Compliance
output "security_compliance" {
  description = "Security compliance features enabled"
  value = {
    admin_user_disabled = !module.acr_registry.admin_enabled
    public_access_disabled = !module.acr_registry.public_network_access_enabled
    private_endpoint_enabled = module.acr_network.private_endpoint_enabled
    encryption_enabled = module.acr_registry.encryption_enabled
    trust_policy_enabled = module.acr_registry.trust_policy_enabled
    quarantine_policy_enabled = module.acr_registry.quarantine_policy_enabled
    zone_redundancy_enabled = module.acr_registry.zone_redundancy_enabled
    geo_replication_enabled = length(module.acr_registry.georeplications) > 0
    retention_policy_enabled = module.acr_registry.retention_policy_enabled
  }
}