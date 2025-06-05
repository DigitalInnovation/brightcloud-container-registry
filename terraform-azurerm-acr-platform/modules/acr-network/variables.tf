variable "registry_name" {
  type        = string
  description = "Name of the container registry"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing the registry"
}

variable "create_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the registry"
  default     = true
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network for private endpoint"
  default     = null
}

variable "vnet_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the virtual network"
  default     = null
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet for private endpoint"
  default     = null
}

variable "network_security_group_name" {
  type        = string
  description = "Name of the network security group to add rules to"
  default     = null
}

variable "nsg_rule_priority" {
  type        = number
  description = "Priority for NSG rules"
  default     = 1000
  
  validation {
    condition     = var.nsg_rule_priority >= 100 && var.nsg_rule_priority <= 4096
    error_message = "NSG rule priority must be between 100 and 4096."
  }
}

variable "allowed_source_address_prefixes" {
  type        = list(string)
  description = "List of source address prefixes allowed to access ACR"
  default     = []
}

variable "create_application_security_group" {
  type        = bool
  description = "Whether to create an application security group for ACR clients"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to network resources"
  default = {
    Purpose   = "acr-networking"
    ManagedBy = "terraform"
  }
}