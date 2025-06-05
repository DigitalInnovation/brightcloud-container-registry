import * as core from '@actions/core';
import { ImagePromoter } from './image-promoter';
import { PromotionValidator } from './promotion-validator';
import { AzureAuthenticator } from './azure-authenticator';

interface PromotionInputs {
  sourceRegistry: string;
  targetRegistry: string;
  sourceEnvironment: string;
  targetEnvironment: string;
  teamName: string;
  imageName: string;
  sourceTag: string;
  targetTag: string;
  azureClientId: string;
  azureTenantId: string;
  azureSubscriptionId: string;
  dryRun: boolean;
  force: boolean;
}

async function run(): Promise<void> {
  try {
    // Parse inputs
    const inputs: PromotionInputs = {
      sourceRegistry: core.getInput('source-registry', { required: true }),
      targetRegistry: core.getInput('target-registry', { required: true }),
      sourceEnvironment: core.getInput('source-environment', { required: true }),
      targetEnvironment: core.getInput('target-environment', { required: true }),
      teamName: core.getInput('team-name', { required: true }),
      imageName: core.getInput('image-name', { required: true }),
      sourceTag: core.getInput('source-tag', { required: true }),
      targetTag: core.getInput('target-tag') || core.getInput('source-tag', { required: true }),
      azureClientId: core.getInput('azure-client-id', { required: true }),
      azureTenantId: core.getInput('azure-tenant-id', { required: true }),
      azureSubscriptionId: core.getInput('azure-subscription-id', { required: true }),
      dryRun: core.getBooleanInput('dry-run'),
      force: core.getBooleanInput('force')
    };

    core.info('🚀 Starting ACR image promotion...');
    core.info(`Source: ${inputs.sourceRegistry}/${inputs.sourceEnvironment}/${inputs.teamName}/${inputs.imageName}:${inputs.sourceTag}`);
    core.info(`Target: ${inputs.targetRegistry}/${inputs.targetEnvironment}/${inputs.teamName}/${inputs.imageName}:${inputs.targetTag}`);

    // Validate promotion request
    const validator = new PromotionValidator();
    const validationResult = await validator.validate(inputs);
    
    if (!validationResult.isValid) {
      throw new Error(`Validation failed: ${validationResult.errors.join(', ')}`);
    }

    core.info('✅ Promotion validation passed');

    // Authenticate with Azure
    const authenticator = new AzureAuthenticator();
    const credential = await authenticator.authenticate({
      clientId: inputs.azureClientId,
      tenantId: inputs.azureTenantId,
      subscriptionId: inputs.azureSubscriptionId
    });

    core.info('✅ Azure authentication successful');

    // Perform promotion
    const promoter = new ImagePromoter(credential);
    const result = await promoter.promote({
      sourceRegistry: inputs.sourceRegistry,
      targetRegistry: inputs.targetRegistry,
      sourceEnvironment: inputs.sourceEnvironment,
      targetEnvironment: inputs.targetEnvironment,
      teamName: inputs.teamName,
      imageName: inputs.imageName,
      sourceTag: inputs.sourceTag,
      targetTag: inputs.targetTag,
      dryRun: inputs.dryRun,
      force: inputs.force
    });

    // Set outputs
    core.setOutput('source-image', result.sourceImage);
    core.setOutput('target-image', result.targetImage);
    core.setOutput('result', result.status);
    core.setOutput('target-digest', result.targetDigest);

    if (inputs.dryRun) {
      core.info('🧪 Dry run completed successfully - no changes made');
    } else {
      core.info('🎉 Image promotion completed successfully');
    }

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    core.setFailed(`❌ Image promotion failed: ${errorMessage}`);
  }
}

run();