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
  environment = "prod"
  tags = {
    Environment = local.environment
    Purpose     = "brightcloud-acr"
    ManagedBy   = "terraform"
    CostCenter  = "platform"
    Criticality = "high"
  }
}

# ACR Registry Module
module "acr_registry" {
  source = "../../modules/acr-registry"

  acr_name_prefix     = "brightcloudprod"
  resource_group_name = var.resource_group_name
  location            = var.location
  create_resource_group = var.create_resource_group

  # Supported environments for prod registry
  supported_environments = ["preproduction", "production"]

  # Security settings - more restrictive for prod
  public_network_access_enabled = false # Always false for prod
  zone_redundancy_enabled       = true
  network_default_action        = "Deny"
  allowed_ip_ranges            = var.allowed_ip_ranges
  allowed_subnets              = var.allowed_subnets

  # Geo-replication for prod - more extensive
  georeplications = [
    {
      location                = "West Europe"
      zone_redundancy_enabled = true
    },
    {
      location                = "UK South"
      zone_redundancy_enabled = true
    }
  ]

  # Production policies - more conservative
  trust_policy_enabled      = true
  quarantine_policy_enabled = true
  retention_policy_enabled  = true
  retention_policy_days     = var.retention_policy_days
  export_policy_enabled     = false # Disable export for prod security

  # ABAC
  repository_scoped_permissions_enabled = true

  # No direct GitHub Actions push to prod - only promotion
  github_actions_sp_object_id = null

  # Encryption (optional for prod)
  encryption_enabled            = var.encryption_enabled
  encryption_key_vault_key_id   = var.encryption_key_vault_key_id

  tags = local.tags
}

# RBAC Configuration - more restrictive for prod
module "acr_rbac" {
  source = "../../modules/acr-rbac"

  registry_name       = module.acr_registry.registry_name
  resource_group_name = module.acr_registry.resource_group_name

  supported_environments = ["preproduction", "production"]

  # Team access configuration - limited for prod
  teams = var.teams

  # Service principals - promotion only for GitHub Actions
  github_actions_principal_id = var.github_actions_principal_id
  monitoring_principal_ids    = var.monitoring_principal_ids
  compute_principal_ids       = var.compute_principal_ids

  depends_on = [module.acr_registry]
}

# Network Configuration - mandatory for prod
module "acr_network" {
  source = "../../modules/acr-network"

  registry_name       = module.acr_registry.registry_name
  resource_group_name = module.acr_registry.resource_group_name

  create_private_endpoint     = true # Always true for prod
  virtual_network_name        = var.virtual_network_name
  vnet_resource_group_name    = var.vnet_resource_group_name
  subnet_name                 = var.subnet_name
  network_security_group_name = var.network_security_group_name

  allowed_source_address_prefixes   = var.allowed_source_address_prefixes
  create_application_security_group = true # Always create for prod

  tags = local.tags

  depends_on = [module.acr_registry]
}