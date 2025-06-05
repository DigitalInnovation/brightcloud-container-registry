import * as core from '@actions/core';
import * as exec from '@actions/exec';
import { TokenCredential } from '@azure/core-auth';

export interface PromotionResult {
  sourceImage: string;
  targetImage: string;
  status: 'success' | 'skipped' | 'failed';
  targetDigest?: string;
  message?: string;
}

export interface PromotionConfig {
  sourceRegistry: string;
  targetRegistry: string;
  sourceEnvironment: string;
  targetEnvironment: string;
  teamName: string;
  imageName: string;
  sourceTag: string;
  targetTag: string;
  dryRun: boolean;
  force: boolean;
}

export class ImagePromoter {
  constructor(private credential: TokenCredential) {}

  async promote(config: PromotionConfig): Promise<PromotionResult> {
    const sourceImage = `${config.sourceRegistry}/${config.sourceEnvironment}/${config.teamName}/${config.imageName}:${config.sourceTag}`;
    const targetImage = `${config.targetRegistry}/${config.targetEnvironment}/${config.teamName}/${config.imageName}:${config.targetTag}`;

    core.info(`🔍 Verifying source image exists: ${sourceImage}`);
    
    // Verify source image exists
    const sourceExists = await this.imageExists(sourceImage);
    if (!sourceExists) {
      throw new Error(`Source image does not exist: ${sourceImage}`);
    }

    core.info('✅ Source image verified');

    // Check if target image already exists
    const targetExists = await this.imageExists(targetImage);
    if (targetExists && !config.force) {
      return {
        sourceImage,
        targetImage,
        status: 'skipped',
        message: 'Target image already exists. Use force=true to overwrite.'
      };
    }

    if (config.dryRun) {
      core.info('🧪 Dry run mode - would promote image but making no changes');
      return {
        sourceImage,
        targetImage,
        status: 'success',
        message: 'Dry run completed successfully'
      };
    }

    // Perform the actual promotion
    core.info(`🚚 Promoting image: ${sourceImage} → ${targetImage}`);
    
    try {
      // Use ACR import to copy the image
      await this.importImage(config, sourceImage, targetImage);
      
      // Get the digest of the promoted image
      const targetDigest = await this.getImageDigest(targetImage);
      
      core.info(`✅ Image promoted successfully with digest: ${targetDigest}`);
      
      return {
        sourceImage,
        targetImage,
        status: 'success',
        targetDigest,
        message: 'Image promoted successfully'
      };
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to promote image: ${errorMessage}`);
    }
  }

  private async imageExists(imageRef: string): Promise<boolean> {
    try {
      const registry = this.extractRegistry(imageRef);
      await this.loginToRegistry(registry);
      
      let output = '';
      const exitCode = await exec.exec('docker', ['manifest', 'inspect', imageRef], {
        ignoreReturnCode: true,
        silent: true,
        listeners: {
          stdout: (data: Buffer) => {
            output += data.toString();
          }
        }
      });

      return exitCode === 0;
    } catch (error) {
      return false;
    }
  }

  private async importImage(config: PromotionConfig, sourceImage: string, targetImage: string): Promise<void> {
    const sourceRegistry = this.extractRegistryName(config.sourceRegistry);
    const targetRegistry = this.extractRegistryName(config.targetRegistry);
    
    // Use az acr import command for efficient cross-registry copy
    const importArgs = [
      'acr', 'import',
      '--name', targetRegistry,
      '--source', sourceImage,
      '--image', `${config.targetEnvironment}/${config.teamName}/${config.imageName}:${config.targetTag}`,
      '--force' // Always use force for import as we've already validated
    ];

    // If source and target are different registries, specify source registry
    if (sourceRegistry !== targetRegistry) {
      importArgs.push('--registry', sourceRegistry);
    }

    const exitCode = await exec.exec('az', importArgs, {
      ignoreReturnCode: true
    });

    if (exitCode !== 0) {
      throw new Error(`ACR import command failed with exit code ${exitCode}`);
    }
  }

  private async getImageDigest(imageRef: string): Promise<string> {
    const registry = this.extractRegistry(imageRef);
    await this.loginToRegistry(registry);
    
    let output = '';
    const exitCode = await exec.exec('docker', ['inspect', '--format={{.RepoDigests}}', imageRef], {
      ignoreReturnCode: true,
      silent: true,
      listeners: {
        stdout: (data: Buffer) => {
          output += data.toString();
        }
      }
    });

    if (exitCode !== 0) {
      throw new Error('Failed to get image digest');
    }

    // Parse digest from output
    const digestMatch = output.match(/sha256:[a-f0-9]{64}/);
    if (!digestMatch) {
      throw new Error('Could not extract digest from docker inspect output');
    }

    return digestMatch[0];
  }

  private async loginToRegistry(registry: string): Promise<void> {
    // Use Azure CLI to login to ACR with the current credential
    const registryName = this.extractRegistryName(registry);
    
    const exitCode = await exec.exec('az', ['acr', 'login', '--name', registryName], {
      ignoreReturnCode: true,
      silent: true
    });

    if (exitCode !== 0) {
      throw new Error(`Failed to login to registry: ${registry}`);
    }
  }

  private extractRegistry(imageRef: string): string {
    // Extract registry URL from full image reference
    const parts = imageRef.split('/');
    return parts[0];
  }

  private extractRegistryName(registryUrl: string): string {
    // Extract registry name from URL (e.g., brightcloudproduction from brightcloudproduction.azurecr.io)
    return registryUrl.replace('.azurecr.io', '');
  }
}