locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name

  # Generate registry name with proper validation
  registry_name = var.registry_name != null ? var.registry_name : "${var.registry_name_prefix}${random_string.suffix.result}"

  # Common tags merged with provided tags
  common_tags = merge(
    {
      "Environment"    = var.environment
      "ManagedBy"      = "Terraform"
      "Project"        = "BrightCloud-ACR"
      "CostCenter"     = var.cost_center
      "BusinessUnit"   = var.business_unit
      "CreatedDate"    = formatdate("YYYY-MM-DD", timestamp())
    },
    var.tags
  )

  # Environment-specific retention policies with validation
  retention_policies = {
    sandbox = {
      enabled = true
      days    = 3
    }
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

  # Get retention policy for current environment
  retention_policy = lookup(local.retention_policies, var.environment, {
    enabled = var.retention_policy_enabled
    days    = var.retention_policy_days
  })

  # Validate SKU compatibility with features
  is_premium_sku = var.sku == "Premium"
  
  # Features requiring Premium SKU
  premium_features = [
    var.zone_redundancy_enabled,
    var.trust_policy_enabled,
    var.quarantine_policy_enabled,
    length(var.georeplications) > 0,
    var.encryption_enabled
  ]
  
  has_premium_features = anytrue(local.premium_features)
}

data "azurerm_client_config" "current" {}

# Random suffix for unique naming when registry_name is not provided
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Validation checks
resource "null_resource" "validation" {
  lifecycle {
    precondition {
      condition = length(local.registry_name) <= 50 && length(local.registry_name) >= 5
      error_message = "Registry name must be between 5 and 50 characters."
    }
    
    precondition {
      condition = can(regex("^[a-zA-Z0-9]*$", local.registry_name))
      error_message = "Registry name can only contain alphanumeric characters."
    }
    
    precondition {
      condition = !local.has_premium_features || local.is_premium_sku
      error_message = "Premium SKU is required for zone redundancy, trust policy, quarantine policy, geo-replication, or encryption features."
    }
    
    precondition {
      condition = contains(["Basic", "Standard", "Premium"], var.sku)
      error_message = "SKU must be one of: Basic, Standard, Premium."
    }
    
    precondition {
      condition = contains(["sandbox", "pr", "dev", "perf", "preproduction", "production"], var.environment)
      error_message = "Environment must be one of: sandbox, pr, dev, perf, preproduction, production."
    }
  }
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = local.registry_name
  resource_group_name = local.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Security settings
  public_network_access_enabled = var.public_network_access_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  export_policy_enabled         = var.export_policy_enabled

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Trust Policy for content signing (Premium SKU only)
  dynamic "trust_policy" {
    for_each = local.is_premium_sku ? [1] : []
    content {
      enabled = var.trust_policy_enabled
    }
  }

  # Quarantine Policy for security scanning (Premium SKU only)
  dynamic "quarantine_policy" {
    for_each = local.is_premium_sku ? [1] : []
    content {
      enabled = var.quarantine_policy_enabled
    }
  }

  # Retention Policy - use environment-specific settings
  retention_policy {
    days    = local.retention_policy.days
    enabled = local.retention_policy.enabled
  }

  # Geo-replication for disaster recovery (Premium SKU only)
  dynamic "georeplications" {
    for_each = local.is_premium_sku ? var.georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = local.common_tags
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

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = var.ignore_changes
  }

  depends_on = [null_resource.validation]
}

# User-assigned identity for encryption (if enabled)
resource "azurerm_user_assigned_identity" "encryption" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${local.registry_name}-encryption-identity"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.common_tags
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
