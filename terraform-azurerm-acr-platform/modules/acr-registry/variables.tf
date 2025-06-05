variable "acr_name_prefix" {
  type        = string
  description = "Prefix for the ACR name (e.g., 'brightcloudsandbox', 'brightcloudnonprod', 'brightcloudprod')"
  
  validation {
    condition = can(regex("^[a-zA-Z0-9]{5,40}$", var.acr_name_prefix)) && length(var.acr_name_prefix) <= 40
    error_message = "ACR name prefix must be 5-40 characters and contain only alphanumeric characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region for the registry"
  default     = "North Europe"
}

variable "create_resource_group" {
  type        = bool
  description = "Whether to create a new resource group"
  default     = false
}

variable "supported_environments" {
  type        = list(string)
  description = "List of supported environment prefixes for repositories"
  default     = ["pr", "dev", "perf", "preproduction", "production"]
  
  validation {
    condition = alltrue([
      for env in var.supported_environments : 
      contains(["pr", "dev", "perf", "preproduction", "production"], env)
    ])
    error_message = "Supported environments must be one of: pr, dev, perf, preproduction, production."
  }
}

# Security and Network Configuration
variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access to the registry"
  default     = false
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable zone redundancy for the registry"
  default     = true
}

variable "network_default_action" {
  type        = string
  description = "Default action for network rule set"
  default     = "Deny"
  
  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "Network default action must be 'Allow' or 'Deny'."
  }
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "List of IP ranges allowed to access the registry"
  default     = []
}

variable "allowed_subnets" {
  type        = list(string)
  description = "List of subnet IDs allowed to access the registry"
  default     = []
}

# Geo-replication
variable "georeplications" {
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  description = "List of geo-replication configurations"
  default = [
    {
      location                = "West Europe"
      zone_redundancy_enabled = true
    }
  ]
}

# Policies
variable "trust_policy_enabled" {
  type        = bool
  description = "Enable content trust policy"
  default     = true
}

variable "quarantine_policy_enabled" {
  type        = bool
  description = "Enable quarantine policy for security scanning"
  default     = true
}

variable "retention_policy_enabled" {
  type        = bool
  description = "Enable retention policy for untagged manifests"
  default     = true
}

variable "retention_policy_days" {
  type        = number
  description = "Number of days to retain untagged manifests"
  default     = 7
  
  validation {
    condition     = var.retention_policy_days >= 0 && var.retention_policy_days <= 365
    error_message = "Retention policy days must be between 0 and 365."
  }
}

variable "export_policy_enabled" {
  type        = bool
  description = "Enable export policy"
  default     = true
}

# ABAC Configuration
variable "repository_scoped_permissions_enabled" {
  type        = bool
  description = "Enable repository-scoped permissions (ABAC)"
  default     = true
}

# Encryption
variable "encryption_enabled" {
  type        = bool
  description = "Enable customer-managed key encryption"
  default     = false
}

variable "encryption_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for encryption"
  default     = null
}

# GitHub Actions Integration
variable "github_actions_sp_object_id" {
  type        = string
  description = "Object ID of the GitHub Actions service principal"
  default     = null
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "shared"
    Purpose     = "container-registry"
    ManagedBy   = "terraform"
  }
}