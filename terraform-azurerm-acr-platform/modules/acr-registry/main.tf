locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name

  # Generate a unique suffix for the ACR name based on resource group and location
  acr_name_suffix = substr(sha256("${local.resource_group_name}-${var.location}"), 0, 8)
  acr_name        = "${var.acr_name_prefix}${local.acr_name_suffix}"

  # Environment-specific retention policies
  retention_policies = {
    pr = {
      enabled = true
      days    = 30
    }
    dev = {
      enabled = true
      days    = 720
    }
    perf = {
      enabled = true
      days    = 60
    }
    preproduction = {
      enabled = true
      days    = 720
    }
    production = {
      enabled = true
      days    = 3650
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = local.resource_group_name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false

  # Security settings
  public_network_access_enabled = var.public_network_access_enabled
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = true
  network_rule_bypass_option    = "AzureServices"
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  export_policy_enabled         = var.export_policy_enabled

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Trust Policy for content signing
  trust_policy {
    enabled = var.trust_policy_enabled
  }

  # Quarantine Policy for security scanning
  quarantine_policy {
    enabled = var.quarantine_policy_enabled
  }

  # Retention Policy - applied to all environments
  retention_policy {
    days    = var.retention_policy_days
    enabled = var.retention_policy_enabled
  }

  # Geo-replication for disaster recovery
  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = var.tags
    }
  }

  # Network rules for private access
  dynamic "network_rule_set" {
    for_each = length(var.allowed_subnets) > 0 || length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = var.network_default_action

      dynamic "ip_rule" {
        for_each = var.allowed_ip_ranges
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = var.allowed_subnets
        content {
          action    = "Allow"
          subnet_id = virtual_network.value
        }
      }
    }
  }

  # Customer-managed encryption (optional)
  dynamic "encryption" {
    for_each = var.encryption_enabled ? [1] : []
    content {
      enabled            = true
      key_vault_key_id   = var.encryption_key_vault_key_id
      identity_client_id = azurerm_user_assigned_identity.encryption[0].client_id
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

# User-assigned identity for encryption (if enabled)
resource "azurerm_user_assigned_identity" "encryption" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${local.acr_name}-encryption-identity"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Enable ABAC (Attribute-Based Access Control) for repository-scoped permissions
resource "null_resource" "enable_abac" {
  count = var.repository_scoped_permissions_enabled ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      az acr update \
        --name ${azurerm_container_registry.acr.name} \
        --resource-group ${azurerm_container_registry.acr.resource_group_name} \
        --anonymous-pull-enabled false \
        --data-endpoint-enabled true
      
      # Enable repository-scoped permissions (ABAC)
      az rest \
        --method PATCH \
        --url "https://management.azure.com/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_container_registry.acr.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${azurerm_container_registry.acr.name}?api-version=2023-07-01" \
        --body '{
          "properties": {
            "policies": {
              "repositoryScopedPermissions": {
                "status": "enabled"
              }
            }
          }
        }'
    EOT
  }

  depends_on = [azurerm_container_registry.acr]
}

# Create environment-specific repository prefixes using scope maps
resource "azurerm_container_registry_scope_map" "environment_scopes" {
  for_each                = toset(var.supported_environments)
  name                    = "${each.key}-scope"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_container_registry.acr.resource_group_name

  actions = [
    "repositories/${each.key}/**/content/read",
    "repositories/${each.key}/**/content/write",
    "repositories/${each.key}/**/content/delete",
    "repositories/${each.key}/**/metadata/read",
    "repositories/${each.key}/**/metadata/write"
  ]
}

# GitHub Actions service principal (created externally, referenced here)
data "azuread_service_principal" "github_actions" {
  count     = var.github_actions_sp_object_id != null ? 1 : 0
  object_id = var.github_actions_sp_object_id
}

# Role assignment for GitHub Actions service principal
resource "azurerm_role_assignment" "github_actions_push" {
  count                = var.github_actions_sp_object_id != null ? 1 : 0
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azuread_service_principal.github_actions[0].object_id
}
