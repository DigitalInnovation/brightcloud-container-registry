output "registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.acr.name
}

output "registry_url" {
  description = "Login server URL of the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "registry_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.acr.id
}

output "registry_identity" {
  description = "System-assigned managed identity of the registry"
  value = {
    principal_id = azurerm_container_registry.acr.identity[0].principal_id
    tenant_id    = azurerm_container_registry.acr.identity[0].tenant_id
    type         = azurerm_container_registry.acr.identity[0].type
  }
}

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

output "resource_group_name" {
  description = "Name of the resource group containing the registry"
  value       = local.resource_group_name
}

output "location" {
  description = "Location of the registry"
  value       = azurerm_container_registry.acr.location
}

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

output "encryption_identity" {
  description = "User-assigned identity for encryption (if enabled)"
  value = var.encryption_enabled ? {
    id           = azurerm_user_assigned_identity.encryption[0].id
    principal_id = azurerm_user_assigned_identity.encryption[0].principal_id
    client_id    = azurerm_user_assigned_identity.encryption[0].client_id
    tenant_id    = azurerm_user_assigned_identity.encryption[0].tenant_id
  } : null
}