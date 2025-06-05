# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🏛️ M&S Technology Standards Compliance

This repository has been configured to comply with M&S Technology Standards:

### ✅ **Compliant Standards**
- **GitHub Repository Standard**: catalog-info.yaml, README.md, CONTRIBUTING.md, pull_request_template.md ✅
- **Language & Framework Standard**: TypeScript, Terraform, Bash all approved ✅
- **Testing Standard**: Jest + Terratest with comprehensive coverage ✅
- **Versioning Standard**: Semantic versioning with automated releases ✅
- **Security Tooling Standard**: CodeQL, Semgrep, Trivy, Snyk integration ✅

### 📋 **Standards Implementation Details**
- **Semantic Versioning**: Automated via semantic-release with conventional commits
- **Security Scanning**: Multi-layer approach with SARIF reporting to GitHub Security
- **Status Badges**: Integrated in README.md for build status and quality metrics
- **Dependency Management**: Renovate configuration for automated updates

## Project Architecture

The BrightCloud Container Registry Platform implements a comprehensive Azure Container Registry (ACR) solution with three main components:

### 1. Terraform Infrastructure (`terraform-azurerm-acr-platform/`)
- **Three-tier registry architecture**: sandbox, nonprod, production with configurable domain names
- **Modular design**: `acr-registry` (core infrastructure), `acr-rbac` (access control), `acr-network` (security)
- **ABAC permissions**: Repository-scoped permissions using Azure's ABAC system for team isolation
- **Environment-specific retention policies**: Different retention periods per environment (sandbox: 3 days, PR: 30 days, dev: 720 days, production: 3650 days)

### 2. GitHub Actions (`acr-image-promotion-action/`)
- **Family of promotion actions**: Five specialized actions for different promotion scenarios
- **TypeScript-based**: Uses Node.js 20 runtime with Azure SDK integration
- **Strict validation**: Prevents image renaming during promotion to maintain security boundaries

### 3. Backstage Template (`backstage-acr-template/`)
- **Service scaffolding**: Creates new services with pre-configured ACR integration
- **Team-based organization**: Generates workflows based on team name and environment tier selection

## Image Naming Convention

All images follow the pattern: `{registry-url}/{environment}/{team-name}/{image-name}:{tag}`

Examples:
- `brightcloudsandbox.azurecr.io/sandbox/experimental-team/poc-service:v0.1.0`
- `brightcloudnonprod.azurecr.io/dev/frontend-team/web-app:v1.2.3`
- `brightcloudproduction.azurecr.io/production/backend-team/api-service:v2.1.0`

## Development Commands

### ACR Image Promotion Action
```bash
# Install dependencies
cd acr-image-promotion-action
npm install

# Build the action
npm run build

# Run tests
npm test
npm run test:watch

# Lint and format
npm run lint
npm run lint:fix
npm run format

# Package for distribution
npm run package
```

### Terraform Operations
```bash
# Navigate to environment (sandbox, nonprod, or production)
cd terraform-azurerm-acr-platform/environments/sandbox

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"

# Format code
terraform fmt -recursive
```

## Key Security Features

- **Team isolation**: Teams can only access repositories under their namespace (`{environment}/{team-name}/*`)
- **ABAC scope maps**: Each environment has dedicated scope maps restricting repository access
- **Registry boundaries**: Controlled promotion between nonprod and production registries
- **OIDC authentication**: GitHub Actions authenticate using workload identity federation

## Architecture Patterns

### Promotion Flow
1. **Sandbox experimentation** → `sandbox/sandbox/experimental-team/service:experiment-456`
2. **PR builds** → `nonprod/pr/team-name/service:pr-123-abc`
3. **Dev deployment** → `nonprod/dev/team-name/service:v1.2.3`
4. **Cross-registry promotion** → `production/production/team-name/service:v1.2.3`

### Team Access Model
Teams are configured in Terraform with:
- Principal ID (Azure AD group)
- Allowed environments (pr, dev, perf, preproduction, production)
- Role assignments (AcrPush, AcrPull)

### Module Dependencies
- `acr-registry` must be deployed first
- `acr-rbac` depends on registry output
- `acr-network` depends on registry output
- All modules use consistent tagging strategy

## Testing

### Action Tests
Located in `acr-image-promotion-action/tests/`:
- Jest configuration with 30s timeout
- Setup file for test environment
- Coverage collection excludes main.ts entry point

### Terraform Validation
- Use `terraform validate` and `terraform plan` before applying
- Check module interdependencies when making changes
- Verify ABAC scope map configurations match team requirements