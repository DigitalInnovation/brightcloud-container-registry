# Variables for Complete Example

variable "location" {
  type        = string
  description = "Azure region for all resources"
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

# GitHub Actions Service Principal
variable "github_actions_sp_object_id" {
  type        = string
  description = "Object ID of the GitHub Actions service principal for OIDC authentication"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.github_actions_sp_object_id))
    error_message = "GitHub Actions service principal object ID must be a valid GUID."
  }
}

# Team Principal IDs (Azure AD Groups)
variable "frontend_team_principal_id" {
  type        = string
  description = "Azure AD group object ID for the frontend development team"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.frontend_team_principal_id))
    error_message = "Frontend team principal ID must be a valid GUID."
  }
}

variable "backend_team_principal_id" {
  type        = string
  description = "Azure AD group object ID for the backend development team"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.backend_team_principal_id))
    error_message = "Backend team principal ID must be a valid GUID."
  }
}

variable "platform_team_principal_id" {
  type        = string
  description = "Azure AD group object ID for the platform engineering team"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.platform_team_principal_id))
    error_message = "Platform team principal ID must be a valid GUID."
  }
}

variable "security_team_principal_id" {
  type        = string
  description = "Azure AD group object ID for the security team"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.security_team_principal_id))
    error_message = "Security team principal ID must be a valid GUID."
  }
}

# Network Configuration
variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the ACR private endpoint"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.private_endpoint_subnet_id))
    error_message = "Private endpoint subnet ID must be a valid Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for ACR private endpoint resolution"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/.+$", var.private_dns_zone_id))
    error_message = "Private DNS zone ID must be a valid Azure private DNS zone resource ID."
  }
}

# Monitoring Configuration
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for monitoring and alerting"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/.+$", var.log_analytics_workspace_id))
    error_message = "Log Analytics workspace ID must be a valid Azure workspace resource ID."
  }
}

variable "alert_action_group_id" {
  type        = string
  description = "Action group ID for ACR alerts"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Insights/actionGroups/.+$", var.alert_action_group_id))
    error_message = "Alert action group ID must be a valid Azure action group resource ID."
  }
}