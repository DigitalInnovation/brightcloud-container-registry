config {
  # Enable all rules by default
  disabled_by_default = false
  
  # Disable rules that conflict with our standards
  disabled_rules = []
  
  # Set the format for output
  format = "compact"
  
  # Force colors in output (useful for CI)
  force = false
}

# Azure provider plugin for enhanced Azure-specific linting
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Terraform core rules
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# Azure-specific rules (enabled with azurerm plugin)
rule "azurerm_container_registry_public_access_disabled" {
  enabled = true
}

rule "azurerm_storage_account_public_access_disabled" {
  enabled = true
}

rule "azurerm_key_vault_purge_protection_enabled" {
  enabled = true
}

rule "azurerm_network_security_group_no_inbound_22" {
  enabled = true
}

rule "azurerm_network_security_group_no_inbound_3389" {
  enabled = true
}

rule "azurerm_resource_group_location" {
  enabled = true
}

# Custom rules for our specific requirements
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}