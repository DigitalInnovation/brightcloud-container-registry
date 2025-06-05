package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestACRRBACModule(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)
	mockRegistryId := fmt.Sprintf("/subscriptions/test-sub/resourceGroups/%s/providers/Microsoft.ContainerRegistry/registries/%s", expectedResourceGroupName, expectedRegistryName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/acr-rbac",
		Vars: map[string]interface{}{
			"registry_id":     mockRegistryId,
			"registry_name":   expectedRegistryName,
			"environment":     "test",
			"domain_name":     "brightcloud.test",
			"teams": []map[string]interface{}{
				{
					"name":               "test-team",
					"principal_id":       "11111111-1111-1111-1111-111111111111",
					"allowed_environments": []string{"pr", "dev"},
				},
				{
					"name":               "prod-team",
					"principal_id":       "22222222-2222-2222-2222-222222222222",
					"allowed_environments": []string{"pr", "dev", "production"},
				},
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	scopeMaps := terraform.OutputList(t, terraformOptions, "scope_map_names")
	tokens := terraform.OutputList(t, terraformOptions, "token_names")

	expectedScopeMaps := []string{
		fmt.Sprintf("%s-test-pr-scope", expectedRegistryName),
		fmt.Sprintf("%s-test-dev-scope", expectedRegistryName),
		fmt.Sprintf("%s-test-production-scope", expectedRegistryName),
	}

	expectedTokens := []string{
		fmt.Sprintf("%s-test-pr-token", expectedRegistryName),
		fmt.Sprintf("%s-test-dev-token", expectedRegistryName),
		fmt.Sprintf("%s-test-production-token", expectedRegistryName),
	}

	for _, expectedScopeMap := range expectedScopeMaps {
		assert.Contains(t, scopeMaps, expectedScopeMap)
	}

	for _, expectedToken := range expectedTokens {
		assert.Contains(t, tokens, expectedToken)
	}
}

func TestACRRBACModuleEmptyTeams(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)
	mockRegistryId := fmt.Sprintf("/subscriptions/test-sub/resourceGroups/%s/providers/Microsoft.ContainerRegistry/registries/%s", expectedResourceGroupName, expectedRegistryName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/acr-rbac",
		Vars: map[string]interface{}{
			"registry_id":   mockRegistryId,
			"registry_name": expectedRegistryName,
			"environment":   "test",
			"domain_name":   "brightcloud.test",
			"teams":         []map[string]interface{}{},
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	scopeMaps := terraform.OutputList(t, terraformOptions, "scope_map_names")
	tokens := terraform.OutputList(t, terraformOptions, "token_names")

	assert.Empty(t, scopeMaps)
	assert.Empty(t, tokens)
}