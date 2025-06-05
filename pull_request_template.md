# Pull Request Template

## Description
Brief description of what this PR accomplishes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Infrastructure/configuration update
- [ ] Refactoring (no functional changes)

## Component Areas (check all that apply)
- [ ] Terraform Infrastructure (`terraform-azurerm-acr-platform/`)
- [ ] GitHub Actions (`acr-image-promotion-action/`)
- [ ] Backstage Template (`backstage-acr-template/`)
- [ ] Documentation
- [ ] Security/compliance

## Testing
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] I have tested this change in a development environment
- [ ] Integration tests pass (if applicable)

### Test Evidence
<!-- Provide screenshots, test output, or other evidence of testing -->

## Security Considerations
- [ ] This change does not introduce new security vulnerabilities
- [ ] I have reviewed the security implications of this change
- [ ] Secret management practices have been followed
- [ ] ABAC/RBAC permissions are correctly configured (if applicable)

## Team Access Impact
- [ ] This change does not affect team-based access controls
- [ ] If team access is modified, I have documented the changes
- [ ] Image naming conventions are maintained

## Documentation
- [ ] I have updated the README if needed
- [ ] I have updated relevant documentation in `/docs`
- [ ] API documentation has been updated (if applicable)
- [ ] CLAUDE.md has been updated if architecture changes were made

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] My changes generate no new warnings
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes follow semantic versioning principles

## Infrastructure Changes
<!-- If this PR includes Terraform changes -->
- [ ] I have run `terraform plan` and reviewed the output
- [ ] I have tested changes in sandbox environment first
- [ ] Resource naming follows established conventions
- [ ] Tagging strategy is consistent

## GitHub Actions Changes
<!-- If this PR includes action changes -->
- [ ] I have tested the action changes locally
- [ ] Action inputs and outputs are properly documented
- [ ] Backwards compatibility is maintained (or breaking changes are documented)
- [ ] I have updated the action version appropriately

## Release Notes
<!-- What should be included in release notes for this change? -->

## Additional Context
<!-- Add any other context about the problem or solution here -->

## Related Issues
<!-- Link to related issues: Fixes #123, Relates to #456 -->