# ${{ values.name }}

${{ values.description }}

## 🚀 Getting Started

This service is configured with Azure Container Registry (ACR) integration for automated image building and promotion across environments.

### Container Registry Configuration

- **Registry Tier**: ${{ values.acr_environment_tier }}
{%- if values.acr_environment_tier == "nonprod" %}
- **Registry URL**: `${{ values.registry_url_nonprod }}`
- **Supported Environments**: ${{ values.initial_environments | join(", ") }}
{%- elif values.acr_environment_tier == "sandbox" %}
- **Registry URL**: `${{ values.registry_url_sandbox }}`
- **Purpose**: Experimentation and POC work
{%- endif %}
- **Image Name**: `${{ values.name }}`
- **Container Port**: `${{ values.container_port }}`

### Image Naming Convention

Images are tagged using the following pattern:
```
{registry-url}/{environment}/{image-name}:{tag}
```

Examples:
{%- if values.acr_environment_tier == "nonprod" %}
- PR builds: `${{ values.registry_url_nonprod }}/pr/${{ values.name }}:pr-123-abc1234`
- Dev builds: `${{ values.registry_url_nonprod }}/dev/${{ values.name }}:dev-abc1234`
{%- if "perf" in values.initial_environments %}
- Perf builds: `${{ values.registry_url_nonprod }}/perf/${{ values.name }}:perf-abc1234`
{%- endif %}
{%- elif values.acr_environment_tier == "sandbox" %}
- Sandbox builds: `${{ values.registry_url_sandbox }}/sandbox/${{ values.name }}:feature-abc1234`
{%- endif %}

## 🔄 CI/CD Workflows

### Automated Build and Push

The repository includes GitHub Actions workflows for:

1. **Build and Push** (`.github/workflows/build-and-push.yml`)
   - Triggers on push to `main`/`develop` and pull requests
   - Builds Docker image using provided Dockerfile
   - Pushes to appropriate environment in ACR
   - Adds PR comments with image details

{%- if values.enable_production_promotion %}
2. **Production Promotion** (`.github/workflows/promote-to-production.yml`)
   - Manual workflow for promoting images to production
   - Two-stage promotion: nonprod → preproduction → production
   - Requires environment approvals for safety
{%- endif %}

### Required Secrets

Configure these secrets in your GitHub repository:

- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID  
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

## 🛠️ Local Development

### Prerequisites

- ${{ values.language | title }}
- Docker
- Azure CLI (for ACR access)

### Running Locally

1. Install dependencies:
{%- if values.language == "nodejs" %}
   ```bash
   npm install
   ```

2. Start the development server:
   ```bash
   npm run dev
   ```
{%- elif values.language == "java" %}
   ```bash
   mvn install
   ```

2. Start the application:
   ```bash
   mvn spring-boot:run
   ```
{%- elif values.language == "python" %}
   ```bash
   pip install -r requirements.txt
   ```

2. Start the application:
   {%- if values.framework == "fastapi" %}
   ```bash
   uvicorn main:app --reload --port ${{ values.container_port }}
   ```
   {%- elif values.framework == "flask" %}
   ```bash
   python app.py
   ```
   {%- else %}
   ```bash
   python main.py
   ```
   {%- endif %}
{%- elif values.language == "dotnet" %}
   ```bash
   dotnet restore
   ```

2. Start the application:
   ```bash
   dotnet run
   ```
{%- elif values.language == "go" %}
   ```bash
   go mod download
   ```

2. Start the application:
   ```bash
   go run main.go
   ```
{%- endif %}

3. Access the application at `http://localhost:${{ values.container_port }}`

### Building Docker Image Locally

```bash
docker build -t ${{ values.name }} .
docker run -p ${{ values.container_port }}:${{ values.container_port }} ${{ values.name }}
```

## 🏗️ Architecture

This service follows BrightCloud architecture patterns:

- **Build Once, Deploy Everywhere**: Images are built once and promoted through environments
- **Immutable Tags**: Uses git SHA-based tags instead of moving tags like `latest`
- **Environment Separation**: Clear separation between nonprod and prod registries
- **Security**: OIDC authentication and ABAC permissions for registry access

## 📊 Monitoring and Observability

The service includes:

- Health check endpoint at `/health`
- Container health checks in Dockerfile
- Structured logging (configure as needed for your framework)

## 🔒 Security Features

- **Non-root user**: Container runs as non-privileged user
- **ABAC permissions**: Repository-scoped access control in ACR
- **OIDC authentication**: Secure GitHub Actions integration
- **Network policies**: Private endpoints and network restrictions

## 🚀 Deployment

{%- if values.enable_production_promotion %}
### Production Deployment

1. Ensure your image is available in the perf environment
2. Go to Actions → "Promote to Production"
3. Enter the source tag (e.g., `perf-abc1234`)
4. Approve the preproduction deployment
5. Approve the production deployment

### Promotion Path

```
pr → dev → perf → preproduction → production
```
{%- else %}
### Deployment

Images are automatically built and pushed to the ${{ values.acr_environment_tier }} registry. Use your preferred deployment method (Kubernetes, Container Apps, etc.) to deploy the images.
{%- endif %}

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request
4. Review the automated image build in PR comments
5. Merge to trigger deployment builds

## 📝 License

Copyright © ${{ "now" | date("YYYY") }} BrightCloud Platform Team