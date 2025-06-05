# Migration Guide: GHCR to Azure Container Registry

This guide provides step-by-step instructions for migrating from GitHub Container Registry (GHCR) to Azure Container Registry (ACR) for BrightCloud applications.

## Overview

The migration follows a dual-push strategy to ensure zero downtime:

1. **Phase 1**: Deploy ACR infrastructure
2. **Phase 2**: Configure dual-push (GHCR + ACR)
3. **Phase 3**: Update applications to pull from ACR
4. **Phase 4**: Remove GHCR push and cleanup

## Prerequisites

- [ ] ACR infrastructure deployed using this Terraform platform
- [ ] GitHub Actions service principal with ACR permissions
- [ ] Teams onboarded with appropriate RBAC
- [ ] Network connectivity configured (private endpoints if needed)

## Phase 1: Infrastructure Deployment

### 1.1 Deploy Non-Production Registry

```bash
# Clone the repository
git clone https://github.com/DigitalInnovation/terraform-azurerm-acr-platform.git
cd terraform-azurerm-acr-platform/environments/nonprod

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Deploy via GitHub Actions or manually
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 1.2 Deploy Production Registry

```bash
cd ../prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Deploy via GitHub Actions (recommended) or manually
# Production requires manual approval workflows
```

### 1.3 Verify Deployment

```bash
# Test registry connectivity
az acr login --name brightcloudnonprod-abc123
az acr login --name brightcloudprod-def456

# Verify ABAC is enabled
az acr show --name brightcloudnonprod-abc123 --query "policies.repositoryScopedPermissions.status"
```

## Phase 2: Configure Dual-Push

### 2.1 Update GitHub Actions Workflows

For each application repository, update the build workflow to push to both registries:

```yaml
# .github/workflows/build-and-push.yml
name: Build and Push Container Image

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  # Legacy GHCR
  GHCR_REGISTRY: ghcr.io
  # New ACR
  ACR_REGISTRY: brightcloudnonprod-abc123.azurecr.io
  IMAGE_NAME: my-service

permissions:
  id-token: write
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Determine environment and tag
        id: env
        run: |
          if [ "${{ github.event_name }}" = "pull_request" ]; then
            echo "environment=pr" >> $GITHUB_OUTPUT
            echo "tag=pr-${{ github.event.pull_request.number }}-${{ github.sha }}" >> $GITHUB_OUTPUT
          elif [ "${{ github.ref }}" = "refs/heads/main" ]; then
            echo "environment=dev" >> $GITHUB_OUTPUT
            echo "tag=dev-${{ github.sha }}" >> $GITHUB_OUTPUT
          fi

      # Login to both registries
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.GHCR_REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Login to ACR
        run: az acr login --name brightcloudnonprod-abc123

      # Build image
      - name: Build image
        run: docker build -t temp-image .

      # Push to GHCR (legacy)
      - name: Push to GHCR
        run: |
          GHCR_IMAGE="${GHCR_REGISTRY}/${{ github.repository }}:${{ steps.env.outputs.tag }}"
          docker tag temp-image "$GHCR_IMAGE"
          docker push "$GHCR_IMAGE"
          echo "ghcr_image=$GHCR_IMAGE" >> $GITHUB_OUTPUT
        id: ghcr

      # Push to ACR (new)
      - name: Push to ACR
        run: |
          ACR_IMAGE="${ACR_REGISTRY}/${{ steps.env.outputs.environment }}/${IMAGE_NAME}:${{ steps.env.outputs.tag }}"
          docker tag temp-image "$ACR_IMAGE"
          docker push "$ACR_IMAGE"
          echo "acr_image=$ACR_IMAGE" >> $GITHUB_OUTPUT
        id: acr

      - name: Add PR comment
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const comment = `## 🐳 Container Images Built
            
            **GHCR**: \`${{ steps.ghcr.outputs.ghcr_image }}\`
            **ACR**: \`${{ steps.acr.outputs.acr_image }}\`
            
            Both images are identical and available for deployment testing.
            `;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

### 2.2 Test Dual-Push

1. Create a test PR in an application repository
2. Verify both GHCR and ACR images are pushed
3. Test pulling from both registries
4. Validate image digests match

## Phase 3: Update Applications to Use ACR

### 3.1 Update Kubernetes Manifests

```yaml
# Before (GHCR)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    spec:
      containers:
        - name: my-service
          image: ghcr.io/digitalinnovation/my-service:dev-abc1234

# After (ACR)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    spec:
      containers:
        - name: my-service
          image: brightcloudnonprod-abc123.azurecr.io/dev/my-service:dev-abc1234
      imagePullSecrets:
        - name: acr-secret  # If using service principal auth
```

### 3.2 Update Helm Charts

```yaml
# values.yaml
image:
  registry: brightcloudnonprod-abc123.azurecr.io
  repository: dev/my-service
  tag: dev-abc1234
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: acr-secret
```

### 3.3 Update Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  my-service:
    image: brightcloudnonprod-abc123.azurecr.io/dev/my-service:dev-abc1234
    ports:
      - "8080:8080"
```

### 3.4 Configure Image Pull Secrets

For Kubernetes deployments using service principal authentication:

```bash
# Create image pull secret
kubectl create secret docker-registry acr-secret \
  --docker-server=brightcloudnonprod-abc123.azurecr.io \
  --docker-username=$SERVICE_PRINCIPAL_ID \
  --docker-password=$SERVICE_PRINCIPAL_PASSWORD \
  --namespace=default
```

For managed identity (recommended):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-sa
  annotations:
    azure.workload.identity/client-id: "12345678-1234-1234-1234-123456789012"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    spec:
      serviceAccountName: my-service-sa
      containers:
        - name: my-service
          image: brightcloudnonprod-abc123.azurecr.io/dev/my-service:dev-abc1234
```

## Phase 4: Production Migration

### 4.1 Set Up Image Promotion

```yaml
# .github/workflows/promote-to-production.yml
name: Promote to Production

on:
  workflow_dispatch:
    inputs:
      source-tag:
        description: 'Source tag from perf environment'
        required: true
        type: string

jobs:
  promote:
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
        uses: DigitalInnovation/acr-image-promotion-action@v1
        with:
          source-registry: 'brightcloudnonprod-abc123.azurecr.io'
          target-registry: 'brightcloudprod-def456.azurecr.io'
          source-environment: 'perf'
          target-environment: 'preproduction'
          image-name: 'my-service'
          source-tag: ${{ inputs.source-tag }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### 4.2 Update Production Deployments

Update production Kubernetes manifests, Helm charts, and deployment scripts to use the production ACR registry.

## Phase 5: Cleanup GHCR

### 5.1 Remove GHCR Push from Workflows

Remove GHCR-related steps from GitHub Actions workflows:

```yaml
# Remove these sections:
# - GHCR login
# - GHCR push
# - GHCR environment variables
```

### 5.2 Clean Up GHCR Images

```bash
# Delete old images from GHCR (optional)
# This can be done gradually to maintain rollback capability
```

### 5.3 Revoke Y-Account Permissions

Remove Y-account PAT tokens and service principals that were used for GHCR access.

## Validation Checklist

- [ ] All application images building and pushing to ACR
- [ ] Image promotion workflows working between environments
- [ ] Production deployments using ACR images
- [ ] Monitoring and alerting configured for ACR
- [ ] Network connectivity verified (private endpoints)
- [ ] RBAC permissions working for all teams
- [ ] Backup and disaster recovery tested
- [ ] GHCR dependencies removed from all applications

## Rollback Plan

If issues arise during migration:

1. **Immediate**: Switch back to GHCR images in deployments
2. **Short-term**: Re-enable GHCR push in workflows
3. **Investigation**: Diagnose ACR connectivity or permission issues
4. **Resolution**: Fix issues and retry migration

## Troubleshooting

### Common Issues

1. **Authentication failures**
   - Verify service principal permissions
   - Check OIDC configuration
   - Validate Azure CLI login

2. **Network connectivity**
   - Test private endpoint connectivity
   - Verify DNS resolution
   - Check NSG rules

3. **Permission denied**
   - Verify ABAC repository permissions
   - Check team role assignments
   - Validate scope map configurations

4. **Image promotion failures**
   - Check promotion path validity
   - Verify source image exists
   - Validate environment naming

### Support Contacts

- Platform Team: `platform-team@company.com`
- Azure Support: Create support ticket for Azure-specific issues
- GitHub Issues: Use repository issues for bugs and feature requests

## Post-Migration Optimization

After successful migration:

1. Configure image retention policies
2. Set up monitoring and alerting
3. Implement automated security scanning
4. Optimize geo-replication settings
5. Review and update team permissions
6. Document new processes and procedures