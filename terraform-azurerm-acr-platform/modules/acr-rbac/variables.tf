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
    name                    = string
    service_principal_id    = string  # For automation/push access
    azure_ad_group_id       = string  # For team member read access
    environments           = list(string)
  }))
  description = "Map of teams with service principal for push and AD group for read access"
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
      for team in values(var.teams) : 
      team.service_principal_id != "" && team.azure_ad_group_id != ""
    ])
    error_message = "Both service_principal_id and azure_ad_group_id must be provided for each team."
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