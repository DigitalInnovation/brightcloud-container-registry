# Core Configuration
variable "registry_name" {
  type        = string
  description = "Name of the Azure Container Registry. If not provided, will be generated using registry_name_prefix"
  default     = null

  validation {
    condition = var.registry_name == null || (
      can(regex("^[a-zA-Z0-9]{5,50}$", var.registry_name)) &&
      length(var.registry_name) >= 5 &&
      length(var.registry_name) <= 50
    )
    error_message = "Registry name must be 5-50 characters and contain only alphanumeric characters."
  }
}

variable "registry_name_prefix" {
  type        = string
  description = "Prefix for the ACR name when registry_name is not provided"
  default     = "acr"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{1,42}$", var.registry_name_prefix))
    error_message = "Registry name prefix must be 1-42 characters and contain only alphanumeric characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name cannot be empty."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the registry"
  default     = "North Europe"

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3", "Central US",
      "North Central US", "South Central US", "West Central US",
      "Canada Central", "Canada East",
      "Brazil South",
      "North Europe", "West Europe", "UK South", "UK West",
      "France Central", "Germany West Central", "Norway East", "Switzerland North",
      "UAE North", "South Africa North",
      "East Asia", "Southeast Asia", "Japan East", "Japan West",
      "Korea Central", "Australia East", "Australia Southeast",
      "Central India", "South India", "West India"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (used for tagging and retention policies)"

  validation {
    condition = contains([
      "sandbox", "pr", "dev", "perf", "preproduction", "production"
    ], var.environment)
    error_message = "Environment must be one of: sandbox, pr, dev, perf, preproduction, production."
  }
}

variable "create_resource_group" {
  type        = bool
  description = "Whether to create a new resource group"
  default     = false
}

# SKU and Basic Configuration
variable "sku" {
  type        = string
  description = "SKU tier for the registry"
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  type        = bool
  description = "Enable admin user for the registry"
  default     = false
}

# Security and Network Configuration
variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access to the registry"
  default     = false
}

variable "anonymous_pull_enabled" {
  type        = bool
  description = "Enable anonymous pull access"
  default     = false
}

variable "data_endpoint_enabled" {
  type        = bool
  description = "Enable dedicated data endpoint"
  default     = true
}

variable "network_rule_bypass_option" {
  type        = string
  description = "Network rule bypass option"
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "Network rule bypass option must be 'AzureServices' or 'None'."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable zone redundancy for the registry (Premium SKU only)"
  default     = false
}

variable "export_policy_enabled" {
  type        = bool
  description = "Enable export policy"
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

  validation {
    condition = alltrue([
      for ip in var.allowed_ip_ranges : can(cidrhost(ip, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}

variable "allowed_subnets" {
  type        = list(string)
  description = "List of subnet IDs allowed to access the registry"
  default     = []

  validation {
    condition = alltrue([
      for subnet in var.allowed_subnets : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", subnet))
    ])
    error_message = "All subnet IDs must be valid Azure subnet resource IDs."
  }
}

# Geo-replication (Premium SKU only)
variable "georeplications" {
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  description = "List of geo-replication configurations (Premium SKU only)"
  default     = []

  validation {
    condition = alltrue([
      for geo in var.georeplications : contains([
        "East US", "East US 2", "West US", "West US 2", "West US 3", "Central US",
        "North Central US", "South Central US", "West Central US",
        "Canada Central", "Canada East",
        "Brazil South",
        "North Europe", "West Europe", "UK South", "UK West",
        "France Central", "Germany West Central", "Norway East", "Switzerland North",
        "UAE North", "South Africa North",
        "East Asia", "Southeast Asia", "Japan East", "Japan West",
        "Korea Central", "Australia East", "Australia Southeast",
        "Central India", "South India", "West India"
      ], geo.location)
    ])
    error_message = "All geo-replication locations must be valid Azure regions."
  }
}

# Policies (Premium SKU for some features)
variable "trust_policy_enabled" {
  type        = bool
  description = "Enable content trust policy (Premium SKU only)"
  default     = false
}

variable "quarantine_policy_enabled" {
  type        = bool
  description = "Enable quarantine policy for security scanning (Premium SKU only)"
  default     = false
}

variable "retention_policy_enabled" {
  type        = bool
  description = "Enable retention policy for untagged manifests"
  default     = true
}

variable "retention_policy_days" {
  type        = number
  description = "Number of days to retain untagged manifests (overridden by environment-specific policies)"
  default     = 7

  validation {
    condition     = var.retention_policy_days >= 0 && var.retention_policy_days <= 365
    error_message = "Retention policy days must be between 0 and 365."
  }
}

# ABAC Configuration
variable "repository_scoped_permissions_enabled" {
  type        = bool
  description = "Enable repository-scoped permissions (ABAC)"
  default     = true
}

variable "supported_environments" {
  type        = list(string)
  description = "List of supported environment prefixes for repositories"
  default     = ["sandbox", "pr", "dev", "perf", "preproduction", "production"]

  validation {
    condition = alltrue([
      for env in var.supported_environments :
      contains(["sandbox", "pr", "dev", "perf", "preproduction", "production"], env)
    ])
    error_message = "Supported environments must be from: sandbox, pr, dev, perf, preproduction, production."
  }
}

# Encryption (Premium SKU only)
variable "encryption_enabled" {
  type        = bool
  description = "Enable customer-managed key encryption (Premium SKU only)"
  default     = false
}

variable "encryption_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for encryption"
  default     = null

  validation {
    condition = var.encryption_key_vault_key_id == null || can(regex("^https://[^/]+\\.vault\\.azure\\.net/keys/[^/]+/[^/]+$", var.encryption_key_vault_key_id))
    error_message = "Encryption key vault key ID must be a valid Azure Key Vault key URL."
  }
}

# GitHub Actions Integration
variable "github_actions_sp_object_id" {
  type        = string
  description = "Object ID of the GitHub Actions service principal"
  default     = null

  validation {
    condition = var.github_actions_sp_object_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.github_actions_sp_object_id))
    error_message = "GitHub Actions service principal object ID must be a valid GUID."
  }
}

# Lifecycle Management
variable "prevent_destroy" {
  type        = bool
  description = "Prevent accidental deletion of the registry"
  default     = true
}

variable "ignore_changes" {
  type        = list(string)
  description = "List of attributes to ignore changes for"
  default     = ["tags"]
}

# Business Metadata
variable "cost_center" {
  type        = string
  description = "Cost center for billing and chargeback"
  default     = "Engineering"
}

variable "business_unit" {
  type        = string
  description = "Business unit owning this resource"
  default     = "Platform"
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags : length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be 128 characters or less, and values must be 256 characters or less."
  }
}