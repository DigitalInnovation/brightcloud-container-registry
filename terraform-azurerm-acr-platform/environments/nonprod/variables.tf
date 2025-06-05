variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for nonprod ACR"
  default     = "rg-brightcloud-acr-nonprod"
}

variable "location" {
  type        = string
  description = "Azure region for the nonprod registry"
  default     = "North Europe"
}

variable "create_resource_group" {
  type        = bool
  description = "Whether to create a new resource group"
  default     = true
}

# Security Configuration
variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access (should be false for production)"
  default     = false
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

# Retention Policy
variable "retention_policy_days" {
  type        = number
  description = "Number of days to retain untagged manifests in nonprod"
  default     = 7
}

# Team Access Configuration
variable "teams" {
  type = map(object({
    name           = string
    principal_id   = string
    principal_type = string
    environments   = list(string)
    roles          = list(string)
  }))
  description = "Map of teams and their ACR access configuration for nonprod"
  default     = {}
}

# Service Principal Configuration
variable "github_actions_sp_object_id" {
  type        = string
  description = "Object ID of the GitHub Actions service principal"
  default     = null
}

variable "github_actions_principal_id" {
  type        = string
  description = "Principal ID of the GitHub Actions service principal for RBAC"
  default     = null
}

variable "monitoring_principal_ids" {
  type        = list(string)
  description = "List of monitoring service principal IDs"
  default     = []
}

variable "compute_principal_ids" {
  type        = list(string)
  description = "List of compute service principal IDs (AKS, Container Apps, etc.)"
  default     = []
}

# Network Configuration
variable "create_private_endpoint" {
  type        = bool
  description = "Whether to create private endpoint for nonprod registry"
  default     = false
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network for private endpoint"
  default     = null
}

variable "vnet_resource_group_name" {
  type        = string
  description = "Resource group name containing the virtual network"
  default     = null
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet for private endpoint"
  default     = null
}

variable "network_security_group_name" {
  type        = string
  description = "Name of the network security group for ACR rules"
  default     = null
}

variable "allowed_source_address_prefixes" {
  type        = list(string)
  description = "Source address prefixes allowed in NSG rules"
  default     = []
}

variable "create_application_security_group" {
  type        = bool
  description = "Whether to create application security group"
  default     = false
}