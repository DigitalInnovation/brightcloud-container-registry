terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

locals {
  environment = "sandbox"
  tags = {
    Environment = local.environment
    Purpose     = "brightcloud-acr"
    ManagedBy   = "terraform"
    CostCenter  = "platform"
  }
}

# ACR Registry Module
module "acr_registry" {
  source = "../../modules/acr-registry"

  acr_name_prefix     = "brightcloudsandbox"
  resource_group_name = var.resource_group_name
  location            = var.location
  create_resource_group = var.create_resource_group

  # Supported environments for sandbox registry
  supported_environments = ["sandbox"]

  # Security settings (more relaxed for sandbox)
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = false  # Cost optimization for sandbox
  network_default_action        = "Allow"  # More open for experimentation
  allowed_ip_ranges            = var.allowed_ip_ranges
  allowed_subnets              = var.allowed_subnets

  # No geo-replication for sandbox (cost optimization)
  georeplications = []

  # Policies for sandbox
  trust_policy_enabled      = false  # Relaxed for testing
  quarantine_policy_enabled = false  # Relaxed for testing
  retention_policy_enabled  = true
  retention_policy_days     = var.retention_policy_days
  export_policy_enabled     = true

  # ABAC
  repository_scoped_permissions_enabled = true

  # GitHub Actions integration
  github_actions_sp_object_id = var.github_actions_sp_object_id

  tags = local.tags
}

# RBAC Configuration
module "acr_rbac" {
  source = "../../modules/acr-rbac"

  registry_name       = module.acr_registry.registry_name
  resource_group_name = module.acr_registry.resource_group_name

  supported_environments = ["sandbox"]

  # Team access configuration
  teams = var.teams

  # Service principals
  github_actions_principal_id = var.github_actions_principal_id
  monitoring_principal_ids    = var.monitoring_principal_ids
  compute_principal_ids       = var.compute_principal_ids

  depends_on = [module.acr_registry]
}

# Network Configuration (optional for sandbox)
module "acr_network" {
  source = "../../modules/acr-network"

  registry_name       = module.acr_registry.registry_name
  resource_group_name = module.acr_registry.resource_group_name

  create_private_endpoint     = var.create_private_endpoint
  virtual_network_name        = var.virtual_network_name
  vnet_resource_group_name    = var.vnet_resource_group_name
  subnet_name                 = var.subnet_name
  network_security_group_name = var.network_security_group_name

  allowed_source_address_prefixes   = var.allowed_source_address_prefixes
  create_application_security_group = var.create_application_security_group

  tags = local.tags

  depends_on = [module.acr_registry]
}