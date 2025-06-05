# BrightCloud Container Registry Platform

A comprehensive platform for managing Azure Container Registry (ACR) infrastructure with automated image promotion and team-based access control.

## 🏗️ Repository Structure

```
brightcloud-container-registry/
├── terraform-azurerm-acr-platform/    # Infrastructure as Code
├── acr-image-promotion-action/         # GitHub Actions for image promotion
├── backstage-acr-template/            # Backstage software templates
└── README.md                         # This file
```

## 🎯 Components

### 1. Terraform ACR Platform (`terraform-azurerm-acr-platform/`)
- **Infrastructure as Code** for Azure Container Registry
- **Three-tier architecture**: sandbox, nonprod, prod
- **ABAC permissions** with team-based access control
- **Premium SKU** with geo-replication and security features

### 2. ACR Image Promotion Actions (`acr-image-promotion-action/`)
- **Family of GitHub Actions** for different promotion scenarios
- **Strict validation** preventing image renaming
- **Team-based access patterns** and security controls
- **Developer-friendly UX** with sensible defaults

### 3. Backstage Template (`backstage-acr-template/`)
- **Software template** for creating services with ACR integration
- **Generated workflows** for build, push, and promotion
- **Team-based configuration** and access management

## 🏷️ Image Naming Convention

Images follow this pattern:
```
{registry-url}/{environment}/{team-name}/{image-name}:{tag}
```

Examples:
- `brightcloudnonprod-abc123.azurecr.io/dev/frontend-team/web-app:v1.2.3`
- `brightcloudprod-def456.azurecr.io/prod/backend-team/api-service:v2.1.0`

## 🔒 Team-Based Access Model

Access control is managed at the team level:
- **Team repositories**: `{environment}/{team-name}/*`
- **ABAC scope maps**: Restrict access to team's image repositories
- **Environment progression**: Teams can promote through their allowed environments
- **Cross-team collaboration**: Platform team manages cross-team promotions

## 🚀 Quick Start

### For Platform Teams
1. Deploy ACR infrastructure using Terraform modules
2. Configure team access using RBAC modules
3. Set up GitHub Actions service principals

### For Development Teams
1. Use Backstage template to create new services
2. Build and push images to your team's repositories
3. Use promotion actions to move images through environments

### For Operations Teams
1. Monitor image usage and retention policies
2. Manage team onboarding and access
3. Handle cross-registry promotions to production

## 📋 Common Workflows

### Team Service Creation
```bash
# Use Backstage template
# Select your team name during creation
# Generated image path: registry/env/your-team/service-name
```

### Image Promotion
```yaml
# Promote within team's repositories
- uses: DigitalInnovation/brightcloud-container-registry/acr-image-promotion-action/promote-to-production@v1
  with:
    team-name: 'frontend-team'
    image-name: 'web-app'
    source-tag: 'v1.2.3'
```

### Team Access Management
```hcl
# Add team to Terraform configuration
teams = {
  "new-team" = {
    name           = "New Development Team"
    principal_id   = "team-group-id"
    environments   = ["pr", "dev", "perf"]
    roles          = ["AcrPush", "AcrPull"]
  }
}
```

## 🔐 Security Features

- **Team isolation**: Teams can only access their own image repositories
- **Environment boundaries**: Strict promotion paths between environments
- **Registry boundaries**: Controlled promotion between nonprod and prod
- **OIDC authentication**: Secure GitHub Actions integration
- **Audit logging**: Complete traceability of all operations

## 📚 Documentation

- [Terraform Platform Documentation](terraform-azurerm-acr-platform/README.md)
- [Image Promotion Actions Documentation](acr-image-promotion-action/README.md)
- [Backstage Template Documentation](backstage-acr-template/README.md)
- [Migration Guide](terraform-azurerm-acr-platform/docs/migration-guide.md)
- [Security Guide](terraform-azurerm-acr-platform/docs/security-guide.md)

## 🤝 Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## 📄 License

MIT License - see individual component licenses for details.