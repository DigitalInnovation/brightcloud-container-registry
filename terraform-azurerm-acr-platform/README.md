# Azure Container Registry Platform

This repository contains Terraform modules and configurations for deploying Azure Container Registries (ACR) for the BrightCloud platform.

## Architecture

The platform implements a three-tier registry architecture:

- **Sandbox**: `brightcloudsandbox-{hash}.azurecr.io` - For POC and experimental work
- **Non-Production**: `brightcloudnonprod-{hash}.azurecr.io` - For pr, dev, perf environments
- **Production**: `brightcloudprod-{hash}.azurecr.io` - For preproduction, production environments

## Image Naming Convention

Images follow this pattern:
```
{registry-url}/{environment}/{image-name}:{git-ref}
```

Examples:
- `brightcloudnonprod-abc123.azurecr.io/pr/my-service:feature-branch-sha`
- `brightcloudprod-def456.azurecr.io/production/my-service:v1.2.3`

## Modules

- `modules/acr-registry`: Core ACR infrastructure with Premium SKU, geo-replication, and policies
- `modules/acr-rbac`: RBAC and ABAC configuration for team access
- `modules/acr-network`: Private endpoints and network security rules

## Environments

- `environments/sandbox`: Standalone registry for experimentation
- `environments/nonprod`: Registry for development environments
- `environments/prod`: Registry for production environments

## Usage

See individual environment README files for deployment instructions.

## Security Features

- Premium SKU with geo-replication and zone redundancy
- ABAC (Attribute-Based Access Control) for repository-level permissions
- Private endpoints and network restrictions
- OIDC authentication from GitHub Actions
- Retention policies and quarantine scanning