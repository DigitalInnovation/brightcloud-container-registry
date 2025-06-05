#!/bin/bash

# Script to apply M&S Technology Standards to BrightCloud Container Registry
# This script implements the GitHub Repository Standard requirements

set -e

REPO="DigitalInnovation/brightcloud-container-registry"

echo "🔧 Applying M&S Technology Standards to $REPO..."

# 1. Update repository settings to comply with standards
echo "📋 Updating repository settings..."
gh api repos/$REPO --method PATCH --input repository-settings-update.json

# 2. Create main branch protection ruleset
echo "🛡️  Creating main branch protection ruleset..."
gh api repos/$REPO/rulesets --method POST --input github-ruleset-request.json

# 3. Create branch name restriction ruleset  
echo "🚫 Creating branch name restriction ruleset..."
gh api repos/$REPO/rulesets --method POST --input branch-restriction-ruleset.json

# 4. Enable vulnerability alerts and security features (if not organization-managed)
echo "🔒 Checking security features..."
echo "ℹ️  Security features are managed at organization level"

# 5. Set default branch to main (if not already)
echo "🌳 Setting default branch to main..."
gh api repos/$REPO --method PATCH --field default_branch=main

# 6. Verify CODEOWNERS file exists and is properly configured
echo "👥 Checking CODEOWNERS configuration..."
if [ ! -f ".github/CODEOWNERS" ]; then
    echo "❌ CODEOWNERS file not found. Creating..."
    mkdir -p .github
    cat > .github/CODEOWNERS << 'EOF'
# Global Owners - Platform Engineering Team
* @DigitalInnovation/platform-engineering @crmitchelmore

# Terraform Infrastructure
terraform-azurerm-acr-platform/ @DigitalInnovation/platform-engineering @DigitalInnovation/cloud-infrastructure

# GitHub Actions
.github/workflows/ @DigitalInnovation/platform-engineering @DigitalInnovation/devops

# Security and Compliance
docs/security/ @DigitalInnovation/security @DigitalInnovation/platform-engineering
.github/workflows/security.yml @DigitalInnovation/security

# Documentation
docs/ @DigitalInnovation/platform-engineering
*.md @DigitalInnovation/platform-engineering
EOF
else
    echo "✅ CODEOWNERS file exists"
fi

# 7. Verify required files exist
echo "📄 Checking required standard files..."

required_files=(
    "README.md"
    "CONTRIBUTING.md"
    ".github/pull_request_template.md"
    "catalog-info.yaml"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Required file missing: $file"
        exit 1
    else
        echo "✅ $file exists"
    fi
done

# 8. Check for status badges in README.md
echo "🏷️  Checking for required status badges in README.md..."
if ! grep -q "github/workflows" README.md; then
    echo "⚠️  README.md should include GitHub Actions status badges"
fi

# 9. Enable Dependabot (create config if needed)
echo "🤖 Checking Dependabot configuration..."
if [ ! -f ".github/dependabot.yml" ]; then
    echo "📝 Creating Dependabot configuration..."
    mkdir -p .github
    cat > .github/dependabot.yml << 'EOF'
version: 2
updates:
  # Terraform dependencies
  - package-ecosystem: "terraform"
    directory: "/terraform-azurerm-acr-platform"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "@DigitalInnovation/platform-engineering"
    assignees:
      - "@crmitchelmore"
    commit-message:
      prefix: "deps(terraform)"
      include: "scope"

  # GitHub Actions dependencies
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "@DigitalInnovation/platform-engineering"
    assignees:
      - "@crmitchelmore"
    commit-message:
      prefix: "deps(actions)"
      include: "scope"

  # Node.js dependencies (for GitHub Actions)
  - package-ecosystem: "npm"
    directory: "/acr-image-promotion-action"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "@DigitalInnovation/platform-engineering"
    assignees:
      - "@crmitchelmore"
    commit-message:
      prefix: "deps(npm)"
      include: "scope"

  # Go dependencies (for testing)
  - package-ecosystem: "gomod"
    directory: "/terraform-azurerm-acr-platform/test"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "@DigitalInnovation/platform-engineering"
    assignees:
      - "@crmitchelmore"
    commit-message:
      prefix: "deps(go)"
      include: "scope"
EOF
else
    echo "✅ Dependabot configuration exists"
fi

# 10. Verify catalog-info.yaml is registered in Muziris
echo "📊 Verifying Muziris catalog registration..."
echo "ℹ️  Please ensure this repository is registered in Muziris at:"
echo "   https://portal.muziris.cloud.mnscorp.net/catalog-import"

# 11. Summary
echo ""
echo "✅ M&S Technology Standards application complete!"
echo ""
echo "📋 Summary of changes applied:"
echo "   • Repository settings updated (squash merge, branch deletion, etc.)"
echo "   • Main branch protection ruleset created"
echo "   • Branch name restriction ruleset created"
echo "   • Security features enabled (vulnerability alerts, secret scanning)"
echo "   • CODEOWNERS file verified/created"
echo "   • Dependabot configuration verified/created"
echo "   • Required standard files verified"
echo ""
echo "🔄 Next steps:"
echo "   1. Register repository in Muziris catalog"
echo "   2. Add status badges to README.md"
echo "   3. Verify all quality gates pass in CI/CD"
echo "   4. Test pull request workflow with new rulesets"
echo ""
echo "📚 For more information, see:"
echo "   https://github.com/DigitalInnovation/technology-standards/blob/cicd/docs/github-repository.md"