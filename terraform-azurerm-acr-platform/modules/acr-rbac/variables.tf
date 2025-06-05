variable "registry_name" {
  type        = string
  description = "Name of the container registry"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing the registry"
}

variable "supported_environments" {
  type        = list(string)
  description = "List of supported environment prefixes"
  default     = ["pr", "dev", "perf", "preproduction", "production"]
}

variable "teams" {
  type = map(object({
    name           = string
    principal_id   = string
    principal_type = string # "User", "Group", "ServicePrincipal"
    environments   = list(string)
    roles          = list(string) # ["AcrPull", "AcrPush", "Contributor"]
  }))
  description = "Map of teams and their ACR access configuration"
  default     = {}
  
  validation {
    condition = alltrue([
      for team in values(var.teams) : alltrue([
        for env in team.environments : 
        contains(["pr", "dev", "perf", "preproduction", "production"], env)
      ])
    ])
    error_message = "Team environments must be valid environment names."
  }
  
  validation {
    condition = alltrue([
      for team in values(var.teams) : alltrue([
        for role in team.roles : 
        contains(["AcrPull", "AcrPush", "Contributor", "Reader"], role)
      ])
    ])
    error_message = "Team roles must be valid ACR role names."
  }
}

variable "github_actions_principal_id" {
  type        = string
  description = "Principal ID of the GitHub Actions service principal for image promotion"
  default     = null
}

variable "monitoring_principal_ids" {
  type        = list(string)
  description = "List of principal IDs for monitoring services (Reader access)"
  default     = []
}

variable "compute_principal_ids" {
  type        = list(string)
  description = "List of principal IDs for compute services (AcrPull access)"
  default     = []
}