output "team_tokens" {
  description = "Map of team tokens for repository access"
  value = {
    for team_key, token in azurerm_container_registry_token.team_tokens :
    team_key => {
      id       = token.id
      name     = token.name
      enabled  = token.enabled
    }
  }
  sensitive = true
}

output "custom_role_definition" {
  description = "Custom role definition for ACR promotion"
  value = {
    id   = azurerm_role_definition.acr_promoter.role_definition_id
    name = azurerm_role_definition.acr_promoter.name
  }
}

output "role_assignments" {
  description = "Summary of role assignments created"
  value = {
    team_assignments = [
      for assignment in local.team_role_assignments :
      {
        team        = assignment.team_name
        environment = assignment.environment
        role        = assignment.role
        principal   = assignment.principal_id
      }
    ]
    github_actions_assigned = var.github_actions_principal_id != null
    monitoring_readers      = length(var.monitoring_principal_ids)
    compute_pullers        = length(var.compute_principal_ids)
  }
}