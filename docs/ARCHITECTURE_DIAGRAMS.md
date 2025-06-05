# BrightCloud Container Registry Platform - Architecture Diagrams

## 1. High-Level System Architecture

```mermaid
graph TB
    subgraph "Developer Experience"
        DEV[Developer]
        GH[GitHub Repository]
        BS[Backstage Portal]
    end
    
    subgraph "CI/CD Layer"
        GHA[GitHub Actions]
        OIDC[OIDC Provider]
    end
    
    subgraph "Azure Container Registry Platform"
        subgraph "Registries"
            SAND[Sandbox Registry]
            NONPROD[NonProd Registry]
            PROD[Production Registry]
        end
        
        subgraph "Supporting Services"
            MON[Azure Monitor]
            KV[Key Vault]
            AD[Azure AD]
        end
    end
    
    DEV -->|Code Push| GH
    DEV -->|Service Creation| BS
    GH -->|Trigger| GHA
    GHA -->|Authenticate| OIDC
    OIDC -->|Token| AD
    GHA -->|Push/Pull| SAND
    GHA -->|Promote| NONPROD
    GHA -->|Promote| PROD
    SAND --> MON
    NONPROD --> MON
    PROD --> MON
    PROD -.->|Encryption Keys| KV
```

## 2. Image Promotion Flow

```mermaid
flowchart LR
    subgraph "Development Flow"
        PR[PR Build] -->|Merge| DEV[Dev Environment]
        DEV -->|Test| PERF[Performance Test]
        PERF -->|Validate| PREPROD[Pre-Production]
    end
    
    subgraph "Production Flow"
        PREPROD -->|Approve| PROD[Production]
    end
    
    subgraph "Image Naming"
        PR_IMG[nonprod/pr/team/app:pr-123]
        DEV_IMG[nonprod/dev/team/app:v1.0.0]
        PERF_IMG[nonprod/perf/team/app:v1.0.0]
        PREPROD_IMG[nonprod/preprod/team/app:v1.0.0]
        PROD_IMG[prod/production/team/app:v1.0.0]
    end
    
    PR --> PR_IMG
    DEV --> DEV_IMG
    PERF --> PERF_IMG
    PREPROD --> PREPROD_IMG
    PROD --> PROD_IMG
```

## 3. Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        subgraph "Network Security"
            PE[Private Endpoints]
            NSG[Network Security Groups]
            FW[Azure Firewall]
        end
        
        subgraph "Identity & Access"
            OIDC[OIDC Authentication]
            ABAC[ABAC Permissions]
            RBAC[Azure RBAC]
        end
        
        subgraph "Data Protection"
            TLS[TLS 1.2+ Encryption]
            CMK[Customer Managed Keys]
            SCAN[Vulnerability Scanning]
        end
    end
    
    subgraph "Protected Resources"
        REG[Container Registry]
        IMG[Container Images]
        LOGS[Audit Logs]
    end
    
    PE --> REG
    NSG --> REG
    FW --> REG
    OIDC --> REG
    ABAC --> IMG
    RBAC --> REG
    TLS --> IMG
    CMK --> IMG
    SCAN --> IMG
    REG --> LOGS
```

## 4. Team Access Model

```mermaid
graph TD
    subgraph "Teams"
        TEAM1[Frontend Team]
        TEAM2[Backend Team]
        TEAM3[Platform Team]
    end
    
    subgraph "Permissions"
        SCOPE1[Scope: /frontend-team/*]
        SCOPE2[Scope: /backend-team/*]
        SCOPE3[Scope: /platform-team/*]
    end
    
    subgraph "Repositories"
        subgraph "Frontend Namespace"
            REPO1[dev/frontend-team/web-app]
            REPO2[prod/frontend-team/web-app]
        end
        
        subgraph "Backend Namespace"
            REPO3[dev/backend-team/api]
            REPO4[prod/backend-team/api]
        end
        
        subgraph "Platform Namespace"
            REPO5[dev/platform-team/tools]
            REPO6[prod/platform-team/tools]
        end
    end
    
    TEAM1 -->|ABAC| SCOPE1
    TEAM2 -->|ABAC| SCOPE2
    TEAM3 -->|ABAC| SCOPE3
    
    SCOPE1 -->|Push/Pull| REPO1
    SCOPE1 -->|Push/Pull| REPO2
    SCOPE2 -->|Push/Pull| REPO3
    SCOPE2 -->|Push/Pull| REPO4
    SCOPE3 -->|Push/Pull| REPO5
    SCOPE3 -->|Push/Pull| REPO6
    
    SCOPE1 -.->|Denied| REPO3
    SCOPE2 -.->|Denied| REPO1
```

## 5. Monitoring and Observability

```mermaid
graph LR
    subgraph "Data Sources"
        REG[Container Registry]
        GHA[GitHub Actions]
        NET[Network Logs]
    end
    
    subgraph "Data Collection"
        LA[Log Analytics]
        AI[Application Insights]
        DIAG[Diagnostic Settings]
    end
    
    subgraph "Processing"
        ALERT[Alert Rules]
        QUERY[Log Queries]
        METRIC[Metrics]
    end
    
    subgraph "Outputs"
        EMAIL[Email Alerts]
        TEAMS[Teams Notifications]
        DASH[Dashboards]
        INCIDENT[Incident Creation]
    end
    
    REG --> DIAG
    GHA --> AI
    NET --> LA
    
    DIAG --> LA
    LA --> ALERT
    LA --> QUERY
    AI --> METRIC
    
    ALERT --> EMAIL
    ALERT --> TEAMS
    ALERT --> INCIDENT
    QUERY --> DASH
    METRIC --> DASH
```

## 6. Infrastructure as Code Flow

```mermaid
flowchart TD
    subgraph "Development"
        DEV[Developer] -->|Code| REPO[Git Repository]
        REPO -->|PR| REVIEW[Code Review]
    end
    
    subgraph "CI/CD Pipeline"
        REVIEW -->|Merge| VALIDATE[Terraform Validate]
        VALIDATE -->|Pass| PLAN[Terraform Plan]
        PLAN -->|Review| APPLY[Terraform Apply]
    end
    
    subgraph "Infrastructure"
        APPLY -->|Create| RG[Resource Group]
        APPLY -->|Create| ACR[Container Registry]
        APPLY -->|Configure| RBAC[RBAC & ABAC]
        APPLY -->|Setup| MON[Monitoring]
        
        RG --> ACR
        ACR --> RBAC
        ACR --> MON
    end
    
    subgraph "State Management"
        APPLY -->|Update| STATE[Terraform State]
        STATE -->|Store| BLOB[Azure Blob Storage]
    end
```

## 7. GitHub Actions Workflow

```mermaid
stateDiagram-v2
    [*] --> Triggered: Push/PR/Manual
    
    Triggered --> Authenticate: OIDC Auth
    
    Authenticate --> ValidateInputs: Parse Config
    ValidateInputs --> CheckPermissions: Team Validation
    
    CheckPermissions --> DryRun: Dry Run Enabled
    CheckPermissions --> PullImage: Normal Flow
    
    DryRun --> LogOperation: Simulate
    LogOperation --> [*]: Success
    
    PullImage --> ValidateImage: Check Exists
    ValidateImage --> PushImage: Promote
    PushImage --> UpdateTags: Tag Management
    UpdateTags --> NotifySuccess: Complete
    
    ValidateInputs --> NotifyError: Invalid
    CheckPermissions --> NotifyError: Denied
    ValidateImage --> NotifyError: Not Found
    PushImage --> NotifyError: Failed
    
    NotifySuccess --> [*]: Success
    NotifyError --> [*]: Failure
```

## 8. Disaster Recovery Architecture

```mermaid
graph TB
    subgraph "Primary Region - North Europe"
        PROD1[Production Registry]
        MON1[Monitoring]
        NET1[Network]
    end
    
    subgraph "Secondary Region - West Europe"
        PROD2[DR Registry]
        MON2[DR Monitoring]
        NET2[DR Network]
    end
    
    subgraph "Global Services"
        TM[Traffic Manager]
        AD[Azure AD]
        KV[Key Vault]
    end
    
    subgraph "Replication"
        GEO[Geo-Replication]
        BACKUP[Backup Service]
    end
    
    TM -->|Primary| PROD1
    TM -->|Failover| PROD2
    
    PROD1 <-->|Sync| GEO
    GEO <-->|Sync| PROD2
    
    PROD1 --> BACKUP
    PROD2 --> BACKUP
    
    AD --> PROD1
    AD --> PROD2
    KV --> PROD1
    KV --> PROD2
    
    MON1 -.->|Mirror| MON2
```

## 9. Cost Optimization Model

```mermaid
flowchart TD
    subgraph "Cost Drivers"
        STORAGE[Storage Costs]
        COMPUTE[Compute Costs]
        NETWORK[Network Costs]
        MONITOR[Monitoring Costs]
    end
    
    subgraph "Optimization Strategies"
        subgraph "Storage Optimization"
            RETENTION[Retention Policies]
            COMPRESS[Image Compression]
            DEDUPE[Layer Deduplication]
        end
        
        subgraph "Compute Optimization"
            CACHE[Build Cache]
            SCHEDULE[Off-hours Scaling]
            RESERVE[Reserved Instances]
        end
        
        subgraph "Network Optimization"
            PEERING[VNet Peering]
            ENDPOINT[Private Endpoints]
            CDN[CDN for Distribution]
        end
    end
    
    STORAGE --> RETENTION
    STORAGE --> COMPRESS
    STORAGE --> DEDUPE
    
    COMPUTE --> CACHE
    COMPUTE --> SCHEDULE
    COMPUTE --> RESERVE
    
    NETWORK --> PEERING
    NETWORK --> ENDPOINT
    NETWORK --> CDN
    
    MONITOR --> |Optimize| STORAGE
    MONITOR --> |Optimize| COMPUTE
    MONITOR --> |Optimize| NETWORK
```

## 10. Deployment Architecture

```mermaid
graph TB
    subgraph "Deployment Environments"
        subgraph "Sandbox"
            SAND_TF[Terraform Config]
            SAND_REG[Sandbox Registry]
            SAND_RBAC[Basic RBAC]
        end
        
        subgraph "NonProd"
            NP_TF[Terraform Config]
            NP_REG[NonProd Registry]
            NP_RBAC[Team RBAC]
            NP_MON[Monitoring]
        end
        
        subgraph "Production"
            PROD_TF[Terraform Config]
            PROD_REG[Prod Registry]
            PROD_RBAC[Strict RBAC]
            PROD_MON[Full Monitoring]
            PROD_DR[DR Setup]
        end
    end
    
    subgraph "Shared Components"
        STATE[State Storage]
        SECRETS[Key Vault]
        LOGS[Central Logging]
    end
    
    SAND_TF --> SAND_REG
    SAND_REG --> SAND_RBAC
    
    NP_TF --> NP_REG
    NP_REG --> NP_RBAC
    NP_REG --> NP_MON
    
    PROD_TF --> PROD_REG
    PROD_REG --> PROD_RBAC
    PROD_REG --> PROD_MON
    PROD_REG --> PROD_DR
    
    SAND_TF --> STATE
    NP_TF --> STATE
    PROD_TF --> STATE
    
    SAND_REG --> LOGS
    NP_REG --> LOGS
    PROD_REG --> LOGS
    
    PROD_REG --> SECRETS
```

## Architecture Summary

These diagrams illustrate the comprehensive architecture of the BrightCloud Container Registry Platform:

1. **System Architecture**: Shows the three-tier structure with developer experience, CI/CD, and Azure infrastructure layers
2. **Image Promotion**: Demonstrates the controlled flow of images through environments
3. **Security Layers**: Illustrates defense-in-depth security approach
4. **Team Access Model**: Shows how ABAC enforces team isolation
5. **Monitoring**: Depicts the observability pipeline from data collection to alerting
6. **IaC Flow**: Shows the GitOps workflow for infrastructure changes
7. **GitHub Actions**: Details the state machine for image promotion workflows
8. **Disaster Recovery**: Illustrates the multi-region resilience architecture
9. **Cost Optimization**: Shows strategies for managing platform costs
10. **Deployment Architecture**: Demonstrates the environment-specific deployment model

Each diagram focuses on a specific aspect while maintaining consistency with the overall system design, providing a complete view of the platform's architecture and operational model.