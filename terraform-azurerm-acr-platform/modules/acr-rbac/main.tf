locals {
  # Flatten team-environment combinations for scope map creation
  team_environment_combinations = flatten([
    for team_key, team in var.teams : [
      for env in team.environments : {
        team_key         = team_key
        team_name        = team.name
        environment      = env
        service_principal_id = team.service_principal_id
        azure_ad_group_id   = team.azure_ad_group_id
      }
    ]
  ])
}

# Data source for existing container registry
data "azurerm_container_registry" "acr" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
}

# Data source for environment scope maps
data "azurerm_container_registry_scope_map" "environment_scopes" {
  for_each                = toset(var.supported_environments)
  name                    = "${each.key}-scope"
  container_registry_name = var.registry_name
  resource_group_name     = var.resource_group_name
}

# Create team-specific scope maps for repository access
resource "azurerm_container_registry_scope_map" "team_scopes" {
  for_each = {
    for combo in local.team_environment_combinations :
    "${combo.team_key}-${combo.environment}" => combo
  }

  name                    = "${each.value.team_name}-${each.value.environment}-scope"
  container_registry_name = var.registry_name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/${each.value.environment}/${each.value.team_name}/**/content/read",
    "repositories/${each.value.environment}/${each.value.team_name}/**/content/write",
    "repositories/${each.value.environment}/${each.value.team_name}/**/content/delete",
    "repositories/${each.value.environment}/${each.value.team_name}/**/metadata/read",
    "repositories/${each.value.environment}/${each.value.team_name}/**/metadata/write"
  ]
}

# Service Principal gets AcrPush role with team-specific scope map
resource "azurerm_container_registry_token" "team_sp_tokens" {
  for_each = var.teams
  
  name                    = "${each.value.name}-sp-token"
  container_registry_name = var.registry_name
  resource_group_name     = var.resource_group_name
  enabled                 = true

  # Combine all environment scope maps for this team
  scope_map_id = azurerm_container_registry_scope_map.team_scopes["${each.key}-${each.value.environments[0]}"].id
}

# Azure AD Group gets AcrPull role for reading team images across all environments
resource "azurerm_role_assignment" "team_group_read" {
  for_each = var.teams

  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = each.value.azure_ad_group_id
}

# Service Principal gets AcrPush role at registry level (scoped by tokens)
resource "azurerm_role_assignment" "team_sp_push" {
  for_each = var.teams

  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = each.value.service_principal_id
}

# Custom role definition for ACR promotion
resource "azurerm_role_definition" "acr_promoter" {
  name        = "ACR Image Promoter"
  scope       = data.azurerm_container_registry.acr.id
  description = "Can promote images between environments in ACR"

  permissions {
    actions = [
      "Microsoft.ContainerRegistry/registries/read",
      "Microsoft.ContainerRegistry/registries/artifacts/read",
      "Microsoft.ContainerRegistry/registries/artifacts/write",
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.ContainerRegistry/registries/push/write"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_container_registry.acr.id
  ]
}

# Service principal for GitHub Actions (promotion service)
resource "azurerm_role_assignment" "github_actions_promoter" {
  count                = var.github_actions_principal_id != null ? 1 : 0
  scope                = data.azurerm_container_registry.acr.id
  role_definition_id   = azurerm_role_definition.acr_promoter.role_definition_resource_id
  principal_id         = var.github_actions_principal_id
}

# Reader role for monitoring and observability services
resource "azurerm_role_assignment" "monitoring_reader" {
  for_each = toset(var.monitoring_principal_ids)
  
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "Reader"
  principal_id         = each.value
}

# AcrPull role for AKS clusters and other compute services
resource "azurerm_role_assignment" "compute_pull" {
  for_each = toset(var.compute_principal_ids)
  
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}