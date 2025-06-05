# Primary Outputs
output "registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.acr.name
}

output "registry_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.acr.id
}

output "login_server" {
  description = "Login server URL of the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "registry_url" {
  description = "Login server URL of the container registry (alias for login_server)"
  value       = azurerm_container_registry.acr.login_server
}

# Resource Information
output "resource_group_name" {
  description = "Name of the resource group containing the registry"
  value       = local.resource_group_name
}

output "location" {
  description = "Location of the registry"
  value       = azurerm_container_registry.acr.location
}

output "environment" {
  description = "Environment of the registry"
  value       = var.environment
}

output "sku" {
  description = "SKU tier of the registry"
  value       = azurerm_container_registry.acr.sku
}

# Identity and Security
output "registry_identity" {
  description = "System-assigned managed identity of the registry"
  value = {
    principal_id = azurerm_container_registry.acr.identity[0].principal_id
    tenant_id    = azurerm_container_registry.acr.identity[0].tenant_id
    type         = azurerm_container_registry.acr.identity[0].type
  }
}

output "encryption_identity" {
  description = "User-assigned identity for encryption (if enabled)"
  value = var.encryption_enabled ? {
    id           = azurerm_user_assigned_identity.encryption[0].id
    principal_id = azurerm_user_assigned_identity.encryption[0].principal_id
    client_id    = azurerm_user_assigned_identity.encryption[0].client_id
    tenant_id    = azurerm_user_assigned_identity.encryption[0].tenant_id
  } : null
}

# Configuration Details
output "admin_enabled" {
  description = "Whether admin user is enabled"
  value       = azurerm_container_registry.acr.admin_enabled
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  value       = azurerm_container_registry.acr.public_network_access_enabled
}

output "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled"
  value       = azurerm_container_registry.acr.zone_redundancy_enabled
}

# Geo-replication
output "georeplications" {
  description = "Geo-replication configurations"
  value = [
    for replication in azurerm_container_registry.acr.georeplications :
    {
      location                = replication.location
      zone_redundancy_enabled = replication.zone_redundancy_enabled
    }
  ]
}

# Environment Scope Maps
output "environment_scopes" {
  description = "Map of environment scope maps"
  value = {
    for env, scope in azurerm_container_registry_scope_map.environment_scopes :
    env => {
      id      = scope.id
      name    = scope.name
      actions = scope.actions
    }
  }
}

output "scope_map_names" {
  description = "List of scope map names for easier reference"
  value       = [for scope in azurerm_container_registry_scope_map.environment_scopes : scope.name]
}

# Policies
output "trust_policy_enabled" {
  description = "Whether trust policy is enabled"
  value       = var.trust_policy_enabled && var.sku == "Premium"
}

output "quarantine_policy_enabled" {
  description = "Whether quarantine policy is enabled"
  value       = var.quarantine_policy_enabled && var.sku == "Premium"
}

output "retention_policy" {
  description = "Retention policy configuration"
  value = {
    enabled = local.retention_policy.enabled
    days    = local.retention_policy.days
  }
}

# Network Configuration
output "network_rule_set" {
  description = "Network rule set configuration"
  value = length(azurerm_container_registry.acr.network_rule_set) > 0 ? {
    default_action = azurerm_container_registry.acr.network_rule_set[0].default_action
    ip_rules = [
      for rule in azurerm_container_registry.acr.network_rule_set[0].ip_rule :
      {
        action   = rule.action
        ip_range = rule.ip_range
      }
    ]
    virtual_networks = [
      for rule in azurerm_container_registry.acr.network_rule_set[0].virtual_network :
      {
        action    = rule.action
        subnet_id = rule.subnet_id
      }
    ]
  } : null
}

# Tags
output "tags" {
  description = "Tags applied to the registry"
  value       = azurerm_container_registry.acr.tags
}

# Additional metadata for integration
output "registry_fqdn" {
  description = "Fully qualified domain name of the registry"
  value       = azurerm_container_registry.acr.login_server
}

output "supported_environments" {
  description = "List of supported environments for this registry"
  value       = var.supported_environments
}