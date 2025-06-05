locals {
  # Flatten team-environment-role combinations for easier iteration
  team_role_assignments = flatten([
    for team_key, team in var.teams : [
      for env in team.environments : [
        for role in team.roles : {
          team_key         = team_key
          team_name        = team.name
          environment      = env
          role             = role
          principal_id     = team.principal_id
          principal_type   = team.principal_type
        }
      ]
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

# Create tokens for teams with repository-scoped permissions
resource "azurerm_container_registry_token" "team_tokens" {
  for_each                = var.teams
  name                    = "${each.value.name}-token"
  container_registry_name = var.registry_name
  resource_group_name     = var.resource_group_name
  enabled                 = true

  # Assign scope maps for environments the team has access to
  scope_map_id = data.azurerm_container_registry_scope_map.environment_scopes[each.value.environments[0]].id
}

# Role assignments for teams at registry level
resource "azurerm_role_assignment" "team_registry_roles" {
  for_each = {
    for assignment in local.team_role_assignments :
    "${assignment.team_key}-${assignment.role}" => assignment
  }

  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id

  # Only assign registry-level roles once per team
  count = index([for a in local.team_role_assignments : a.team_key if a.role == each.value.role], each.value.team_key) == 0 ? 1 : 0
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