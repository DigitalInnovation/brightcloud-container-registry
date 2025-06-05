package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestACRNetworkModule(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)
	mockRegistryId := fmt.Sprintf("/subscriptions/test-sub/resourceGroups/%s/providers/Microsoft.ContainerRegistry/registries/%s", expectedResourceGroupName, expectedRegistryName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/acr-network",
		Vars: map[string]interface{}{
			"registry_id":         mockRegistryId,
			"resource_group_name": expectedResourceGroupName,
			"location":            "East US",
			"subnet_id":           "/subscriptions/test-sub/resourceGroups/test-vnet-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet",
			"private_dns_zone_ids": []string{
				"/subscriptions/test-sub/resourceGroups/test-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io",
			},
			"tags": map[string]string{
				"Environment": "test",
				"Purpose":     "terratest",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	privateEndpointName := terraform.Output(t, terraformOptions, "private_endpoint_name")
	privateEndpointId := terraform.Output(t, terraformOptions, "private_endpoint_id")

	assert.Contains(t, privateEndpointName, expectedRegistryName)
	assert.NotEmpty(t, privateEndpointId)
}

func TestACRNetworkModuleMinimal(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedRegistryName := fmt.Sprintf("testacr%s", uniqueID)
	expectedResourceGroupName := fmt.Sprintf("test-rg-%s", uniqueID)
	mockRegistryId := fmt.Sprintf("/subscriptions/test-sub/resourceGroups/%s/providers/Microsoft.ContainerRegistry/registries/%s", expectedResourceGroupName, expectedRegistryName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/acr-network",
		Vars: map[string]interface{}{
			"registry_id":         mockRegistryId,
			"resource_group_name": expectedResourceGroupName,
			"location":            "East US",
			"subnet_id":           "/subscriptions/test-sub/resourceGroups/test-vnet-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	privateEndpointName := terraform.Output(t, terraformOptions, "private_endpoint_name")
	assert.Contains(t, privateEndpointName, expectedRegistryName)
}