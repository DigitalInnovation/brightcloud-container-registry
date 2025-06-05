package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/Azure/azure-sdk-for-go/services/containerregistry/mgmt/2023-07-01/containerregistry"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestACRRegistryModule(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)
	subscriptionID := azure.GetTargetAzureSubscription(t)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/acr-registry",
		Vars: map[string]interface{}{
			"registry_name":                expectedRegistryName,
			"resource_group_name":         expectedResourceGroupName,
			"location":                    "East US",
			"sku":                         "Premium",
			"admin_enabled":               false,
			"public_network_access":       false,
			"network_rule_bypass_option":  "AzureServices",
			"quarantine_policy_enabled":   true,
			"trust_policy_enabled":        true,
			"retention_policy_enabled":    true,
			"retention_policy_days":       30,
			"zone_redundancy_enabled":     false,
			"export_policy_enabled":       false,
			"anonymous_pull_enabled":      false,
			"data_endpoint_enabled":       false,
			"tags": map[string]string{
				"Environment": "test",
				"Purpose":     "terratest",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	actualRegistryName := terraform.Output(t, terraformOptions, "registry_name")
	actualResourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	actualLoginServer := terraform.Output(t, terraformOptions, "login_server")
	actualId := terraform.Output(t, terraformOptions, "id")

	assert.Equal(t, expectedRegistryName, actualRegistryName)
	assert.Equal(t, expectedResourceGroupName, actualResourceGroupName)
	assert.Contains(t, actualLoginServer, expectedRegistryName)
	assert.NotEmpty(t, actualId)

	registry := azure.GetContainerRegistry(t, actualResourceGroupName, actualRegistryName, subscriptionID)
	
	assert.Equal(t, containerregistry.Premium, registry.Sku.Tier)
	assert.Equal(t, containerregistry.Disabled, *registry.AdminUserEnabled)
	assert.Equal(t, containerregistry.Disabled, *registry.PublicNetworkAccess)
	assert.Equal(t, containerregistry.AzureServices, registry.NetworkRuleBypassOptions)
	
	if registry.Policies != nil {
		if registry.Policies.QuarantinePolicy != nil {
			assert.Equal(t, containerregistry.PolicyStatusEnabled, registry.Policies.QuarantinePolicy.Status)
		}
		if registry.Policies.TrustPolicy != nil {
			assert.Equal(t, containerregistry.PolicyStatusEnabled, registry.Policies.TrustPolicy.Status)
		}
		if registry.Policies.RetentionPolicy != nil {
			assert.Equal(t, containerregistry.PolicyStatusEnabled, registry.Policies.RetentionPolicy.Status)
			assert.Equal(t, int32(30), *registry.Policies.RetentionPolicy.Days)
		}
	}
}

func TestACRRegistryModuleWithMinimalConfig(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/acr-registry",
		Vars: map[string]interface{}{
			"registry_name":       expectedRegistryName,
			"resource_group_name": expectedResourceGroupName,
			"location":            "East US",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	actualRegistryName := terraform.Output(t, terraformOptions, "registry_name")
	assert.Equal(t, expectedRegistryName, actualRegistryName)
}

func TestACRRegistryInvalidSKU(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/acr-registry",
		Vars: map[string]interface{}{
			"registry_name":       expectedRegistryName,
			"resource_group_name": expectedResourceGroupName,
			"location":            "East US",
			"sku":                 "InvalidSKU",
		},
	}

	_, err := terraform.InitAndApplyE(t, terraformOptions)
	require.Error(t, err)
}