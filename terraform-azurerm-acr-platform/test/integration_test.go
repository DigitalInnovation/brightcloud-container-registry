package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestACRPlatformIntegration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../environments/sandbox",
		Vars: map[string]interface{}{
			"registry_name":       expectedRegistryName,
			"resource_group_name": expectedResourceGroupName,
			"location":            "East US",
			"domain_name":         "brightcloud.test",
			"teams": []map[string]interface{}{
				{
					"name":               "integration-team",
					"principal_id":       "11111111-1111-1111-1111-111111111111",
					"allowed_environments": []string{"sandbox"},
				},
			},
			"tags": map[string]string{
				"Environment": "test",
				"Purpose":     "integration-test",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	registryName := terraform.Output(t, terraformOptions, "registry_name")
	loginServer := terraform.Output(t, terraformOptions, "login_server")
	registryId := terraform.Output(t, terraformOptions, "registry_id")

	assert.Equal(t, expectedRegistryName, registryName)
	assert.Contains(t, loginServer, expectedRegistryName)
	assert.NotEmpty(t, registryId)

	scopeMaps := terraform.OutputList(t, terraformOptions, "scope_map_names")
	tokens := terraform.OutputList(t, terraformOptions, "token_names")

	expectedScopeMap := fmt.Sprintf("%s-sandbox-sandbox-scope", expectedRegistryName)
	expectedToken := fmt.Sprintf("%s-sandbox-sandbox-token", expectedRegistryName)

	assert.Contains(t, scopeMaps, expectedScopeMap)
	assert.Contains(t, tokens, expectedToken)
}

func TestACRPlatformMultiEnvironment(t *testing.T) {
	environments := []string{"sandbox", "nonprod"}
	
	for _, env := range environments {
		t.Run(fmt.Sprintf("Environment-%s", env), func(t *testing.T) {
			t.Parallel()

			uniqueID := random.UniqueId()
			expectedRegistryName := fmt.Sprintf("test%s%s", env, uniqueID)
			expectedResourceGroupName := fmt.Sprintf("test-%s-rg-%s", env, uniqueID)

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: fmt.Sprintf("../environments/%s", env),
				Vars: map[string]interface{}{
					"registry_name":       expectedRegistryName,
					"resource_group_name": expectedResourceGroupName,
					"location":            "East US",
					"domain_name":         "brightcloud.test",
					"teams": []map[string]interface{}{
						{
							"name":               "test-team",
							"principal_id":       "11111111-1111-1111-1111-111111111111",
							"allowed_environments": []string{env, "pr", "dev"},
						},
					},
				},
			})

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			registryName := terraform.Output(t, terraformOptions, "registry_name")
			assert.Equal(t, expectedRegistryName, registryName)
		})
	}
}