# Terratest Testing Suite

This directory contains comprehensive tests for the BrightCloud Container Registry Platform Terraform modules using [Terratest](https://terratest.gruntwork.io/).

## Structure

```
test/
├── go.mod                  # Go module dependencies
├── Makefile               # Test automation commands
├── README.md              # This file
├── acr_registry_test.go   # ACR Registry module tests
├── acr_rbac_test.go       # ACR RBAC module tests
├── acr_network_test.go    # ACR Network module tests
└── integration_test.go    # End-to-end integration tests
```

## Prerequisites

1. **Go 1.21+**: Required for running Terratest
2. **Azure CLI**: Must be logged in with appropriate permissions
3. **Terraform**: For module validation and deployment
4. **Azure Subscription**: With permissions to create ACR resources

## Setup

```bash
# Install dependencies
make deps

# Verify Azure login
az account show

# Set subscription if needed
export ARM_SUBSCRIPTION_ID="your-subscription-id"
```

## Running Tests

### Quick Start
```bash
# Run all tests
make test

# Run only unit tests (faster)
make test-unit

# Run integration tests
make test-integration
```

### Specific Module Tests
```bash
# Test individual modules
make test-registry
make test-rbac
make test-network
```

### Quality Checks
```bash
# Run all quality checks (recommended for CI)
make quality

# Individual checks
make validate        # Terraform validation
make security-scan   # Security scanning with tfsec
make test-coverage   # Tests with coverage report
```

## Test Categories

### Unit Tests (`*_module_test.go`)
- Test individual Terraform modules in isolation
- Fast execution (typically < 5 minutes per module)
- Mock external dependencies where possible
- Validate module outputs and resource configuration

### Integration Tests (`integration_test.go`)
- Test complete environment deployments
- Slower execution (10-30 minutes)
- Deploy real Azure resources
- Validate end-to-end functionality

## Test Patterns

### Module Testing Pattern
```go
func TestACRRegistryModule(t *testing.T) {
    t.Parallel()  // Enable parallel execution
    
    // Setup unique test resources
    uniqueID := random.UniqueId()
    
    // Configure Terraform options
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/acr-registry",
        Vars: map[string]interface{}{
            // Test variables
        },
    }
    
    // Cleanup on test completion
    defer terraform.Destroy(t, terraformOptions)
    
    // Deploy and test
    terraform.InitAndApply(t, terraformOptions)
    
    // Assertions
    actualOutput := terraform.Output(t, terraformOptions, "output_name")
    assert.Equal(t, expectedValue, actualOutput)
}
```

### Azure Resource Validation
```go
// Validate actual Azure resources
registry := azure.GetContainerRegistry(t, resourceGroupName, registryName, subscriptionID)
assert.Equal(t, containerregistry.Premium, registry.Sku.Tier)
```

## Configuration

### Environment Variables
- `ARM_SUBSCRIPTION_ID`: Azure subscription for testing
- `TEST_TIMEOUT`: Test timeout (default: 60m)
- `TEST_PARALLELISM`: Number of parallel tests (default: 4)

### Test Naming Convention
- `TestACR{Module}Module`: Unit tests for specific modules
- `TestACR{Module}Module{Scenario}`: Specific test scenarios
- `TestACRPlatform{Scenario}`: Integration tests

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run Terratest
  run: |
    cd terraform-azurerm-acr-platform/test
    make quality
  env:
    ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Test Reports
- Coverage reports: `coverage.html`
- Test results: Standard Go test output
- Security scan: tfsec JSON/SARIF reports

## Best Practices

1. **Parallel Execution**: Use `t.Parallel()` for independent tests
2. **Resource Cleanup**: Always use `defer terraform.Destroy()`
3. **Unique Names**: Use `random.UniqueId()` to avoid conflicts
4. **Proper Assertions**: Validate both Terraform outputs and actual Azure resources
5. **Timeout Management**: Set appropriate timeouts for Azure operations
6. **Error Handling**: Use `terraform.InitAndApplyE()` for error validation tests

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Resource Conflicts**
   ```bash
   # Clean up test artifacts
   make clean
   ```

3. **Timeout Issues**
   ```bash
   # Increase timeout
   export TEST_TIMEOUT=90m
   make test
   ```

4. **Parallel Test Failures**
   ```bash
   # Reduce parallelism
   export TEST_PARALLELISM=2
   make test
   ```

### Debug Mode
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
make test-registry
```

## Contributing

1. Add tests for new modules in separate `*_test.go` files
2. Follow the established naming conventions
3. Include both positive and negative test cases
4. Update this README for new test categories
5. Ensure tests are deterministic and can run in parallel