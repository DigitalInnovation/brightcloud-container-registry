# ACR Image Promotion Action

A family of GitHub Actions for promoting container images between Azure Container Registry (ACR) environments with enterprise-grade security, validation, and team isolation.

## 🎯 Quick Start Actions (Recommended)

### 1. Promote to Production
The most common operation - promotes from `dev` in nonprod registry to `production` in production registry.

```yaml
- name: Promote to Production
  uses: DigitalInnovation/acr-image-promotion-action/promote-to-production@v1
  with:
    team-name: 'backend-team'
    image-name: 'my-service'
    source-tag: 'v1.2.3'
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**What it does:**
- Source: `brightcloudnonprod.azurecr.io/dev/backend-team/my-service:v1.2.3`
- Target: `brightcloudproduction.azurecr.io/production/backend-team/my-service:v1.2.3`

### 2. Promote PR to Dev
Common for merging PR builds to development environment.

```yaml
- name: Promote PR to Dev
  uses: DigitalInnovation/acr-image-promotion-action/promote-pr-to-dev@v1
  with:
    team-name: 'frontend-team'
    image-name: 'my-service'
    source-tag: 'pr-123-abc1234'
    target-tag: 'dev-abc1234'
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**What it does:**
- Source: `brightcloudnonprod.azurecr.io/pr/frontend-team/my-service:pr-123-abc1234`
- Target: `brightcloudnonprod.azurecr.io/dev/frontend-team/my-service:dev-abc1234`

### 3. Promote Same Registry
For promotions within the same registry (e.g., dev → perf, perf → preproduction).

```yaml
- name: Promote to Performance
  uses: DigitalInnovation/acr-image-promotion-action/promote-same-registry@v1
  with:
    registry: 'brightcloudnonprod.azurecr.io'
    source-environment: 'dev'
    target-environment: 'perf'
    team-name: 'platform-team'
    image-name: 'my-service'
    source-tag: 'v1.2.3'
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**What it does:**
- Source: `brightcloudnonprod.azurecr.io/dev/platform-team/my-service:v1.2.3`
- Target: `brightcloudnonprod.azurecr.io/perf/platform-team/my-service:v1.2.3`

## 🔧 Advanced Action
For complete control over all parameters.

```yaml
- name: Custom Promotion
  uses: DigitalInnovation/acr-image-promotion-action@v1
  with:
    source-registry: 'brightcloudnonprod.azurecr.io'
    target-registry: 'brightcloudproduction.azurecr.io'
    source-environment: 'perf'
    target-environment: 'preproduction'
    team-name: 'api-team'
    image-name: 'my-service'
    source-tag: 'v1.2.3'
    target-tag: 'v1.2.3-prod'
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## 📋 Complete Workflow Examples

### Production Release Workflow

```yaml
name: Release to Production

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., v1.2.3)'
        required: true
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  promote-to-production:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Promote to Production
        uses: DigitalInnovation/acr-image-promotion-action/promote-to-production@v1
        with:
          team-name: 'backend-team'
          image-name: 'my-service'
          source-tag: ${{ inputs.version }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Merge to Main Workflow

```yaml
name: Deploy to Dev

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  promote-pr-to-dev:
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged == true
    
    steps:
      - name: Get PR number
        id: pr
        run: |
          PR_NUMBER=$(gh pr view --json number --jq .number)
          echo "number=$PR_NUMBER" >> $GITHUB_OUTPUT

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Promote PR to Dev
        uses: DigitalInnovation/acr-image-promotion-action/promote-pr-to-dev@v1
        with:
          team-name: 'frontend-team'
          image-name: 'my-service'
          source-tag: 'pr-${{ steps.pr.outputs.number }}-${{ github.sha }}'
          target-tag: 'dev-${{ github.sha }}'
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Multi-Stage Promotion Workflow

```yaml
name: Multi-Stage Promotion

on:
  workflow_dispatch:
    inputs:
      source-tag:
        description: 'Source tag to promote'
        required: true
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  promote-to-perf:
    runs-on: ubuntu-latest
    environment: performance
    
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Promote to Performance
        uses: DigitalInnovation/acr-image-promotion-action/promote-same-registry@v1
        with:
          registry: 'brightcloudnonprod.azurecr.io'
          source-environment: 'dev'
          target-environment: 'perf'
          team-name: 'platform-team'
          image-name: 'my-service'
          source-tag: ${{ inputs.source-tag }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

  promote-to-preproduction:
    needs: promote-to-perf
    runs-on: ubuntu-latest
    environment: preproduction
    
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Promote to Preproduction
        uses: DigitalInnovation/acr-image-promotion-action@v1
        with:
          source-registry: 'brightcloudnonprod.azurecr.io'
          target-registry: 'brightcloudproduction.azurecr.io'
          source-environment: 'perf'
          target-environment: 'preproduction'
          team-name: 'platform-team'
          image-name: 'my-service'
          source-tag: ${{ inputs.source-tag }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

  promote-to-production:
    needs: promote-to-preproduction
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Promote to Production
        uses: DigitalInnovation/acr-image-promotion-action/promote-same-registry@v1
        with:
          registry: 'brightcloudproduction.azurecr.io'
          source-environment: 'preproduction'
          target-environment: 'production'
          team-name: 'platform-team'
          image-name: 'my-service'
          source-tag: ${{ inputs.source-tag }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## 🔒 Security Features

All actions inherit the same security features:

- ✅ **Strict Same-Name Validation**: Images cannot be renamed during promotion
- 🔒 **Environment Protection**: Validates promotion paths
- 🏗️ **Registry Boundary Controls**: Manages cross-registry promotions
- 🔐 **OIDC Authentication**: Secure authentication using GitHub Actions OIDC
- 🧪 **Dry Run Support**: Test promotions without making changes

## 📊 Action Comparison

| Action | Use Case | Source | Target | Best For |
|--------|----------|--------|--------|----------|
| `promote-to-production` | Deploy to prod | `nonprod/dev/team-name` | `prod/prod/team-name` | Production releases |
| `promote-pr-to-dev` | Merge PR | `nonprod/pr/team-name` | `nonprod/dev/team-name` | CI/CD integration |
| `promote-same-registry` | Environment progression | Same registry | Same registry | Testing phases |
| Advanced action | Custom scenarios | Any registry/env | Any registry/env | Complex workflows |

## 🎯 Common Patterns

### Pattern 1: Standard Pipeline
```
PR → Dev → Perf → Preproduction → Production
```

**Actions to use:**
1. `promote-pr-to-dev` (on merge)
2. `promote-same-registry` (dev → perf)
3. Advanced action (perf → preproduction, cross-registry)
4. `promote-same-registry` (preproduction → production)

### Pattern 2: Simple Pipeline
```
Dev → Production
```

**Action to use:**
- `promote-to-production` (one step!)

### Pattern 3: Feature Branch Testing
```
PR → Dev → Feature Testing
```

**Actions to use:**
1. `promote-pr-to-dev`
2. `promote-same-registry` (dev → feature environment)

## 🛠️ Input Reference

### Common Inputs (All Actions)

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `team-name` | Team name for image organization | ✅ | |
| `image-name` | Image name (no registry/env prefix) | ✅ | |
| `source-tag` | Source image tag | ✅ | |
| `target-tag` | Target image tag | ❌ | `source-tag` |
| `azure-client-id` | Azure client ID | ✅ | |
| `azure-tenant-id` | Azure tenant ID | ✅ | |
| `azure-subscription-id` | Azure subscription ID | ✅ | |
| `dry-run` | Validate without changes | ❌ | `false` |
| `force` | Overwrite existing images | ❌ | `false` |

### Registry Defaults

- **Nonprod Registry**: `brightcloudnonprod.azurecr.io`
- **Prod Registry**: `brightcloudproduction.azurecr.io`

These can be overridden in the quick-start actions if your registries have different names.

## 🔍 Troubleshooting

### Common Issues

1. **Image not found**: Verify source image exists and tag is correct
2. **Permission denied**: Check Azure RBAC and ABAC permissions
3. **Invalid promotion path**: Review allowed environment transitions
4. **Registry name mismatch**: Verify registry URLs match your deployment

### Debug Mode

Enable debug logging:

```yaml
- name: Enable debug logging
  run: echo "ACTIONS_STEP_DEBUG=true" >> $GITHUB_ENV

- name: Promote with debug
  uses: DigitalInnovation/acr-image-promotion-action/promote-to-production@v1
  with:
    team-name: 'backend-team'
    image-name: 'my-service'
    source-tag: 'v1.2.3'
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    dry-run: 'true'  # Safe to test with
```

## 📚 Documentation

- [Migration Guide](../terraform-azurerm-acr-platform/docs/migration-guide.md)
- [Security Guide](../terraform-azurerm-acr-platform/docs/security-guide.md)
- [Terraform ACR Platform](../terraform-azurerm-acr-platform/README.md)

## 🤝 Contributing

See our [contribution guidelines](CONTRIBUTING.md) for details on submitting improvements and bug fixes.

