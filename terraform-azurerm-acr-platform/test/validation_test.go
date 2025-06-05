package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestVariableValidation tests the input validation logic for all modules
func TestVariableValidation(t *testing.T) {
	tests := []struct {
		name        string
		modulePath  string
		vars        map[string]interface{}
		expectError bool
		errorMsg    string
	}{
		// ACR Registry Module Validation Tests
		{
			name:       "Valid registry configuration",
			modulePath: "../modules/acr-registry",
			vars: map[string]interface{}{
				"registry_name":       "validacr123",
				"resource_group_name": "test-rg",
				"location":            "East US",
				"environment":         "dev",
				"sku":                 "Premium",
			},
			expectError: false,
		},
		{
			name:       "Invalid registry name - too short",
			modulePath: "../modules/acr-registry",
			vars: map[string]interface{}{
				"registry_name":       "acr",
				"resource_group_name": "test-rg",
				"location":            "East US",
				"environment":         "dev",
			},
			expectError: true,
			errorMsg:    "Registry name must be 5-50 characters",
		},
		{
			name:       "Invalid environment",
			modulePath: "../modules/acr-registry",
			vars: map[string]interface{}{
				"registry_name":       "validacr123",
				"resource_group_name": "test-rg",
				"location":            "East US",
				"environment":         "invalid-env",
			},
			expectError: true,
			errorMsg:    "Environment must be one of",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: test.modulePath,
				Vars:         test.vars,
			}

			// Initialize terraform
			terraform.Init(t, terraformOptions)

			// Run terraform validate
			if test.expectError {
				// Expect validation to fail
				_, err := terraform.PlanE(t, terraformOptions)
				assert.Error(t, err, "Expected validation error for test: %s", test.name)
				if test.errorMsg != "" {
					assert.Contains(t, err.Error(), test.errorMsg, "Error message should contain expected text")
				}
			} else {
				// Expect validation to pass
				terraform.Validate(t, terraformOptions)
			}
		})
	}
}