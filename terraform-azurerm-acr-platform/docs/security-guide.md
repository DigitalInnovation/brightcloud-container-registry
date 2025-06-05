# Security Guide: Azure Container Registry Platform

This document outlines security best practices, configurations, and procedures for the BrightCloud ACR platform.

## Security Architecture

### Defense in Depth

The ACR platform implements multiple layers of security:

1. **Network Security**: Private endpoints, NSG rules, firewall restrictions
2. **Identity & Access**: ABAC, RBAC, managed identities, OIDC
3. **Data Protection**: Encryption at rest, geo-replication, backup
4. **Content Security**: Image scanning, content trust, quarantine policies
5. **Operational Security**: Audit logging, monitoring, compliance

## Network Security

### Private Endpoints

All production registries **MUST** use private endpoints:

```hcl
# Required for production
create_private_endpoint = true
public_network_access_enabled = false
```

### Network Access Control

```hcl
# Restrict network access
network_default_action = "Deny"

allowed_ip_ranges = [
  "10.0.0.0/8",      # Corporate network
  "172.16.0.0/12"    # Azure VNet ranges
]

allowed_subnets = [
  "/subscriptions/.../subnets/aks-nodes",
  "/subscriptions/.../subnets/build-agents"
]
```

### Network Security Groups

```bash
# Create NSG rule for ACR access
az network nsg rule create \
  --name "Allow-ACR-443" \
  --nsg-name "nsg-acr-prod" \
  --resource-group "rg-networking" \
  --priority 1000 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-range 443 \
  --source-address-prefixes "10.0.0.0/16"
```

## Identity and Access Management

### Service Principals

Create dedicated service principals for different functions:

```bash
# GitHub Actions service principal
az ad sp create-for-rbac \
  --name "sp-acr-github-actions" \
  --role "AcrPush" \
  --scopes "/subscriptions/.../resourceGroups/rg-acr-nonprod" \
  --sdk-auth

# AKS cluster identity
az aks update \
  --name "aks-nonprod" \
  --resource-group "rg-aks" \
  --attach-acr "brightcloudnonprod-abc123"
```

### RBAC Configuration

```hcl
# Team access example
teams = {
  "backend-team" = {
    name           = "Backend Development Team"
    principal_id   = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    principal_type = "Group"
    environments   = ["pr", "dev", "perf"]
    roles          = ["AcrPush", "AcrPull"]
  }
  "security-team" = {
    name           = "Security Team"
    principal_id   = "ffffffff-gggg-hhhh-iiii-jjjjjjjjjjjj"
    principal_type = "Group"
    environments   = ["pr", "dev", "perf", "preproduction", "production"]
    roles          = ["Reader", "AcrPull"]
  }
}
```

### Repository-Scoped Permissions (ABAC)

```bash
# Create scope map for specific repositories
az acr scope-map create \
  --name "team-frontend-scope" \
  --registry "brightcloudnonprod-abc123" \
  --description "Frontend team repository access" \
  --repository "dev/frontend-*" "content/read" "content/write" \
  --repository "pr/frontend-*" "content/read" "content/write"

# Create token for the scope
az acr token create \
  --name "team-frontend-token" \
  --registry "brightcloudnonprod-abc123" \
  --scope-map "team-frontend-scope"
```

## Image Security

### Content Trust (Notary)

Enable content trust to ensure image integrity:

```hcl
trust_policy {
  enabled = true
}
```

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER=https://brightcloudprod-def456.azurecr.io

# Sign and push image
docker build -t brightcloudprod-def456.azurecr.io/production/my-service:v1.0.0 .
docker push brightcloudprod-def456.azurecr.io/production/my-service:v1.0.0
```

### Quarantine Policy

Automatically quarantine images that fail security scans:

```hcl
quarantine_policy {
  enabled = true
}
```

### Vulnerability Scanning

Integrate with Azure Security Center or third-party scanners:

```bash
# Enable Azure Defender for container registries
az security pricing create \
  --name ContainerRegistry \
  --tier Standard
```

### Image Signing with Notation

```bash
# Install notation CLI
# Sign image with certificate
notation sign brightcloudprod-def456.azurecr.io/production/my-service:v1.0.0

# Verify signature
notation verify brightcloudprod-def456.azurecr.io/production/my-service:v1.0.0
```

## Encryption

### Customer-Managed Encryption

For sensitive workloads, enable customer-managed encryption:

```hcl
# Key Vault setup
resource "azurerm_key_vault_key" "acr_encryption" {
  name         = "acr-encryption-key"
  key_vault_id = azurerm_key_vault.acr_kv.id
  key_type     = "RSA"
  key_size     = 2048
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

# ACR with encryption
encryption_enabled             = true
encryption_key_vault_key_id    = azurerm_key_vault_key.acr_encryption.id
```

## GitHub Actions Security

### OIDC Configuration

Use OIDC instead of service principal secrets:

```yaml
# .github/workflows/build.yml
permissions:
  id-token: write
  contents: read

jobs:
  build:
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Environment Protection

```yaml
# Require approval for production deployments
environment: production
```

### Secret Management

Never store credentials in code or logs:

```yaml
# ❌ BAD - Don't do this
run: echo "password123" | docker login registry.com -u user --password-stdin

# ✅ GOOD - Use OIDC or managed identity
- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Compliance and Governance

### Image Tagging Standards

Enforce consistent tagging:

```bash
# ✅ GOOD - Immutable tags
brightcloudprod-def456.azurecr.io/production/my-service:v1.2.3
brightcloudprod-def456.azurecr.io/production/my-service:sha-abc1234

# ❌ BAD - Mutable tags
brightcloudprod-def456.azurecr.io/production/my-service:latest
```

### Retention Policies

Configure appropriate retention for each environment:

```hcl
retention_policy_days = {
  pr            = 3      # Short retention for PR builds
  dev           = 30     # Medium retention for development
  perf          = 60     # Longer retention for performance testing
  preproduction = 180    # Long retention for pre-prod validation
  production    = 365    # Maximum retention for production
}
```

### Audit Logging

Enable comprehensive audit logging:

```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --name "acr-audit-logs" \
  --resource "/subscriptions/.../providers/Microsoft.ContainerRegistry/registries/brightcloudprod-def456" \
  --logs '[
    {
      "category": "ContainerRegistryRepositoryEvents",
      "enabled": true,
      "retentionPolicy": {
        "enabled": true,
        "days": 365
      }
    },
    {
      "category": "ContainerRegistryLoginEvents", 
      "enabled": true,
      "retentionPolicy": {
        "enabled": true,
        "days": 365
      }
    }
  ]' \
  --workspace "/subscriptions/.../resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-security"
```

## Monitoring and Alerting

### Security Monitoring

```kusto
// Log Analytics query for suspicious activity
ContainerRegistryLoginEvents
| where TimeGenerated > ago(24h)
| where LoginResult == "Failed"
| summarize FailedAttempts = count() by UserName, ClientIP
| where FailedAttempts > 10
| order by FailedAttempts desc
```

### Alert Rules

```bash
# Create alert for failed logins
az monitor metrics alert create \
  --name "ACR-Failed-Logins" \
  --resource-group "rg-monitoring" \
  --scopes "/subscriptions/.../providers/Microsoft.ContainerRegistry/registries/brightcloudprod-def456" \
  --condition "count ContainerRegistryLoginEvents | where LoginResult == 'Failed' > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2
```

## Incident Response

### Security Incident Playbook

1. **Detection**: Automated alerts or manual discovery
2. **Assessment**: Determine scope and impact
3. **Containment**: 
   - Disable compromised accounts
   - Block suspicious IP addresses
   - Quarantine affected images
4. **Investigation**: Review audit logs, trace access patterns
5. **Recovery**: 
   - Rotate credentials
   - Update access policies
   - Re-scan and re-deploy clean images
6. **Lessons Learned**: Update security controls

### Emergency Procedures

```bash
# Emergency: Disable public access
az acr update \
  --name "brightcloudprod-def456" \
  --public-network-enabled false

# Emergency: Disable user account
az ad user update \
  --id "user@company.com" \
  --account-enabled false

# Emergency: Revoke service principal access
az role assignment delete \
  --assignee "12345678-1234-1234-1234-123456789012" \
  --role "AcrPush" \
  --scope "/subscriptions/.../resourceGroups/rg-acr-prod"
```

## Security Checklists

### Pre-Deployment Security Checklist

- [ ] Private endpoints configured for production
- [ ] Public network access disabled for production
- [ ] Network security groups configured
- [ ] RBAC permissions properly scoped
- [ ] ABAC repository permissions enabled
- [ ] Content trust policies enabled
- [ ] Quarantine policies enabled
- [ ] Retention policies configured
- [ ] Encryption enabled (if required)
- [ ] Audit logging configured
- [ ] Monitoring and alerting set up

### Regular Security Reviews

**Monthly:**
- [ ] Review access logs for anomalies
- [ ] Audit user permissions and remove unused accounts
- [ ] Check for vulnerable images
- [ ] Review retention policy effectiveness

**Quarterly:**
- [ ] Penetration testing of ACR endpoints
- [ ] Review and update security policies
- [ ] Audit network configurations
- [ ] Review emergency procedures

**Annually:**
- [ ] Full security assessment
- [ ] Compliance audit
- [ ] Update incident response playbooks
- [ ] Security training for teams

## Security Contacts

- **Security Team**: `security@company.com`
- **Platform Team**: `platform@company.com`
- **24/7 Security Hotline**: `+1-xxx-xxx-xxxx`
- **Azure Security Center**: Create support ticket for urgent security issues

## References

- [Azure Container Registry Security Best Practices](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-best-practices)
- [Docker Content Trust](https://docs.docker.com/engine/security/trust/)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)