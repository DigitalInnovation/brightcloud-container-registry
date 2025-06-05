# Azure Container Registry Module

This Terraform module creates and configures an Azure Container Registry (ACR) with enterprise-grade security, compliance, and operational features.

## Features

- **Multi-SKU Support**: Basic, Standard, and Premium tiers with automatic feature enablement
- **Environment-Specific Retention**: Automatic retention policy configuration based on environment
- **Security Hardening**: Network restrictions, private endpoints, and ABAC permissions
- **Business Continuity**: Geo-replication and zone redundancy for Premium SKUs
- **Compliance**: Trust policies, quarantine policies, and audit logging
- **Team Isolation**: Repository-scoped permissions using ABAC
- **Enterprise Tagging**: Comprehensive tagging strategy with business metadata

## Usage

### Basic Usage

```hcl
module "acr" {
  source = "./modules/acr-registry"

  registry_name       = "mycompanyacr"
  resource_group_name = "rg-acr-prod"
  location           = "North Europe"
  environment        = "production"
  
  tags = {
    Owner       = "platform-team"
    Environment = "production"
  }
}
```

### Production Configuration

```hcl
module "acr_production" {
  source = "./modules/acr-registry"

  registry_name       = "mycompanyprod"
  resource_group_name = "rg-acr-production"
  location           = "North Europe"
  environment        = "production"
  sku                = "Premium"

  # Security configuration
  public_network_access_enabled = false
  trust_policy_enabled         = true
  quarantine_policy_enabled    = true
  zone_redundancy_enabled      = true

  # Geo-replication for disaster recovery
  georeplications = [
    {
      location                = "West Europe"
      zone_redundancy_enabled = true
    }
  ]

  # Network restrictions
  network_default_action = "Deny"
  allowed_subnets = [
    "/subscriptions/xxx/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/subnet-aks"
  ]

  # Team permissions
  supported_environments = ["production"]

  # Business metadata
  cost_center    = "Engineering"
  business_unit  = "Platform"

  tags = {
    Owner           = "platform-team"
    Environment     = "production"
    Criticality     = "high"
    DataClassification = "internal"
  }
}
```

### Development Environment

```hcl
module "acr_dev" {
  source = "./modules/acr-registry"

  registry_name       = "mycompanydev"
  resource_group_name = "rg-acr-dev"
  location           = "North Europe"
  environment        = "dev"
  sku                = "Standard"

  # More permissive for development
  public_network_access_enabled = true
  
  # Support multiple environments for dev registry
  supported_environments = ["pr", "dev", "perf"]

  tags = {
    Owner       = "development-team"
    Environment = "development"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| registry_name | Name of the Azure Container Registry | `string` | `null` | no |
| registry_name_prefix | Prefix for auto-generated registry name | `string` | `"acr"` | no |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for the registry | `string` | `"North Europe"` | no |
| environment | Environment name (sandbox/pr/dev/perf/preproduction/production) | `string` | n/a | yes |
| create_resource_group | Whether to create a new resource group | `bool` | `false` | no |
| sku | SKU tier for the registry (Basic/Standard/Premium) | `string` | `"Premium"` | no |
| admin_enabled | Enable admin user for the registry | `bool` | `false` | no |
| public_network_access_enabled | Enable public network access | `bool` | `false` | no |
| anonymous_pull_enabled | Enable anonymous pull access | `bool` | `false` | no |
| data_endpoint_enabled | Enable dedicated data endpoint | `bool` | `true` | no |
| network_rule_bypass_option | Network rule bypass option | `string` | `"AzureServices"` | no |
| zone_redundancy_enabled | Enable zone redundancy (Premium SKU only) | `bool` | `false` | no |
| export_policy_enabled | Enable export policy | `bool` | `true` | no |
| network_default_action | Default action for network rules | `string` | `"Deny"` | no |
| allowed_ip_ranges | List of IP ranges allowed to access the registry | `list(string)` | `[]` | no |
| allowed_subnets | List of subnet IDs allowed to access the registry | `list(string)` | `[]` | no |
| georeplications | List of geo-replication configurations | `list(object)` | `[]` | no |
| trust_policy_enabled | Enable content trust policy (Premium SKU only) | `bool` | `false` | no |
| quarantine_policy_enabled | Enable quarantine policy (Premium SKU only) | `bool` | `false` | no |
| retention_policy_enabled | Enable retention policy | `bool` | `true` | no |
| retention_policy_days | Number of days to retain untagged manifests | `number` | `7` | no |
| repository_scoped_permissions_enabled | Enable ABAC repository-scoped permissions | `bool` | `true` | no |
| supported_environments | List of supported environment prefixes | `list(string)` | `["sandbox", "pr", "dev", "perf", "preproduction", "production"]` | no |
| encryption_enabled | Enable customer-managed key encryption (Premium SKU only) | `bool` | `false` | no |
| encryption_key_vault_key_id | Key Vault key ID for encryption | `string` | `null` | no |
| github_actions_sp_object_id | Object ID of GitHub Actions service principal | `string` | `null` | no |
| prevent_destroy | Prevent accidental deletion | `bool` | `true` | no |
| ignore_changes | List of attributes to ignore changes for | `list(string)` | `["tags"]` | no |
| cost_center | Cost center for billing | `string` | `"Engineering"` | no |
| business_unit | Business unit owning this resource | `string` | `"Platform"` | no |
| tags | Additional tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry_name | Name of the container registry |
| registry_id | ID of the container registry |
| login_server | Login server URL of the container registry |
| registry_url | Login server URL (alias for login_server) |
| resource_group_name | Name of the resource group |
| location | Location of the registry |
| environment | Environment of the registry |
| sku | SKU tier of the registry |
| registry_identity | System-assigned managed identity |
| encryption_identity | User-assigned identity for encryption |
| admin_enabled | Whether admin user is enabled |
| public_network_access_enabled | Whether public network access is enabled |
| zone_redundancy_enabled | Whether zone redundancy is enabled |
| georeplications | Geo-replication configurations |
| environment_scopes | Map of environment scope maps |
| scope_map_names | List of scope map names |
| trust_policy_enabled | Whether trust policy is enabled |
| quarantine_policy_enabled | Whether quarantine policy is enabled |
| retention_policy | Retention policy configuration |
| network_rule_set | Network rule set configuration |
| tags | Tags applied to the registry |
| registry_fqdn | Fully qualified domain name |
| supported_environments | List of supported environments |

## Environment-Specific Retention Policies

The module automatically configures retention policies based on the environment:

| Environment | Retention Period | Purpose |
|-------------|------------------|---------|
| sandbox | 3 days | Short-term experimentation |
| pr | 30 days | Pull request builds |
| dev | 720 days (2 years) | Development artifacts |
| perf | 60 days | Performance testing |
| preproduction | 720 days (2 years) | Pre-production validation |
| production | 3650 days (10 years) | Production releases |

## SKU Feature Matrix

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Repository storage | 10 GB | 100 GB | 500 GB |
| Throughput | Basic | Enhanced | Enhanced |
| Webhooks | 2 | 10 | 500 |
| Geo-replication | ❌ | ❌ | ✅ |
| Content trust | ❌ | ❌ | ✅ |
| Private link | ❌ | ❌ | ✅ |
| Customer-managed keys | ❌ | ❌ | ✅ |
| VNet integration | ❌ | ❌ | ✅ |
| Zone redundancy | ❌ | ❌ | ✅ |
| Quarantine policy | ❌ | ❌ | ✅ |

## Security Features

### Network Security

- **Private Endpoints**: Restrict access to specific VNets and subnets
- **IP Restrictions**: Allow only specific IP ranges
- **Network Rule Bypass**: Configure Azure Services bypass
- **Public Access Control**: Disable public network access for sensitive environments

### Access Control

- **ABAC Permissions**: Repository-scoped permissions for team isolation
- **Managed Identity**: System-assigned identity for secure service-to-service authentication
- **GitHub Actions Integration**: OIDC-based authentication for CI/CD pipelines
- **Admin User Control**: Disable admin user for production environments

### Content Security

- **Trust Policy**: Docker Content Trust for image signing (Premium only)
- **Quarantine Policy**: Automatic vulnerability scanning and quarantine (Premium only)
- **Retention Policies**: Automatic cleanup of untagged manifests
- **Export Policy**: Control image export capabilities

## Business Continuity

### Geo-replication

Premium SKUs support geo-replication for disaster recovery:

```hcl
georeplications = [
  {
    location                = "West Europe"
    zone_redundancy_enabled = true
  },
  {
    location                = "East US"
    zone_redundancy_enabled = false
  }
]
```

### Zone Redundancy

Enable zone redundancy for high availability within a region:

```hcl
zone_redundancy_enabled = true  # Premium SKU only
```

## Team Isolation

The module creates environment-specific scope maps for team isolation:

```
{registry-name}-{environment}-scope
```

Each scope map restricts access to repositories under the pattern:
```
repositories/{environment}/{team-name}/**
```

## Examples

See the [examples](../../examples/) directory for complete implementation examples:

- [Sandbox Environment](../../examples/sandbox/)
- [Development Environment](../../examples/nonprod/)
- [Production Environment](../../examples/production/)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.80.0 |
| azuread | >= 2.40.0 |
| random | >= 3.5.0 |
| null | >= 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.80.0 |
| azuread | >= 2.40.0 |
| random | >= 3.5.0 |
| null | >= 3.2.0 |

## Migration Guide

For guidance on migrating from previous versions, see [Migration Guide](../../docs/migration-guide.md).

## Contributing

Please read our [contributing guidelines](../../CONTRIBUTING.md) before submitting changes.

## License

This module is licensed under the MIT License. See [LICENSE](../../LICENSE) for full details.