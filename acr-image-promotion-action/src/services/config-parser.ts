import * as core from '@actions/core';
import { PromotionConfig, Environment, Logger, ValidationResult, ValidationError } from '../types';

export class ConfigParser {
  constructor(private readonly logger: Logger) {}

  parseInputs(): PromotionConfig {
    this.logger.group('Parsing Action Inputs');
    
    try {
      const config: PromotionConfig = {
        sourceRegistry: this.getRequiredInput('source-registry'),
        sourceImage: this.getRequiredInput('source-image'),
        sourceTag: this.getRequiredInput('source-tag'),
        targetRegistry: this.getRequiredInput('target-registry'),
        targetImage: this.getOptionalInput('target-image'),
        targetTag: this.getOptionalInput('target-tag'),
        targetEnvironment: this.parseEnvironment(this.getRequiredInput('target-environment')),
        teamName: this.getRequiredInput('team-name'),
        allowImageRename: this.getBooleanInput('allow-image-rename', false),
        dryRun: this.getBooleanInput('dry-run', false),
        timeout: this.getNumberInput('timeout', 300000) // 5 minutes default
      };

      const validation = this.validateConfig(config);
      if (!validation.isValid) {
        const errorMessages = validation.errors.map(e => `${e.field}: ${e.message}`).join('\n');
        throw new Error(`Configuration validation failed:\n${errorMessages}`);
      }

      if (validation.warnings.length > 0) {
        validation.warnings.forEach(warning => this.logger.warn(warning));
      }

      this.logger.info('Configuration parsed successfully', {
        sourceRegistry: config.sourceRegistry,
        targetRegistry: config.targetRegistry,
        targetEnvironment: config.targetEnvironment,
        teamName: config.teamName,
        dryRun: config.dryRun
      });

      return config;
    } finally {
      this.logger.groupEnd();
    }
  }

  private validateConfig(config: PromotionConfig): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: string[] = [];

    // Validate registry URLs
    if (!this.isValidRegistryUrl(config.sourceRegistry)) {
      errors.push({
        field: 'source-registry',
        message: 'Invalid source registry URL format',
        code: 'INVALID_REGISTRY_URL'
      });
    }

    if (!this.isValidRegistryUrl(config.targetRegistry)) {
      errors.push({
        field: 'target-registry',
        message: 'Invalid target registry URL format',
        code: 'INVALID_REGISTRY_URL'
      });
    }

    // Validate image names
    if (!this.isValidImageName(config.sourceImage)) {
      errors.push({
        field: 'source-image',
        message: 'Invalid source image name format',
        code: 'INVALID_IMAGE_NAME'
      });
    }

    if (config.targetImage && !this.isValidImageName(config.targetImage)) {
      errors.push({
        field: 'target-image',
        message: 'Invalid target image name format',
        code: 'INVALID_IMAGE_NAME'
      });
    }

    // Validate tags
    if (!this.isValidTag(config.sourceTag)) {
      errors.push({
        field: 'source-tag',
        message: 'Invalid source tag format',
        code: 'INVALID_TAG'
      });
    }

    if (config.targetTag && !this.isValidTag(config.targetTag)) {
      errors.push({
        field: 'target-tag',
        message: 'Invalid target tag format',
        code: 'INVALID_TAG'
      });
    }

    // Validate team name
    if (!this.isValidTeamName(config.teamName)) {
      errors.push({
        field: 'team-name',
        message: 'Team name must be lowercase alphanumeric with hyphens',
        code: 'INVALID_TEAM_NAME'
      });
    }

    // Validate timeout
    if (config.timeout < 10000 || config.timeout > 1800000) { // 10s to 30min
      errors.push({
        field: 'timeout',
        message: 'Timeout must be between 10,000ms and 1,800,000ms',
        code: 'INVALID_TIMEOUT'
      });
    }

    // Business logic validations
    if (config.targetImage && !config.allowImageRename) {
      warnings.push('Target image specified but image renaming is not allowed');
    }

    if (config.sourceRegistry === config.targetRegistry && 
        config.sourceImage === (config.targetImage || config.sourceImage) &&
        config.sourceTag === (config.targetTag || config.sourceTag)) {
      errors.push({
        field: 'target',
        message: 'Source and target cannot be identical',
        code: 'IDENTICAL_SOURCE_TARGET'
      });
    }

    // Production environment validations
    if (config.targetEnvironment === 'production') {
      if (config.allowImageRename) {
        errors.push({
          field: 'allow-image-rename',
          message: 'Image renaming is not allowed when promoting to production',
          code: 'PRODUCTION_RENAME_FORBIDDEN'
        });
      }

      if (!this.isProductionReadyTag(config.targetTag || config.sourceTag)) {
        warnings.push('Tag format may not follow production conventions (expected semantic versioning)');
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }

  private getRequiredInput(name: string): string {
    const value = core.getInput(name, { required: true }).trim();
    if (!value) {
      throw new Error(`Required input '${name}' is missing or empty`);
    }
    return value;
  }

  private getOptionalInput(name: string): string | undefined {
    const value = core.getInput(name).trim();
    return value || undefined;
  }

  private getBooleanInput(name: string, defaultValue = false): boolean {
    const value = core.getInput(name).trim().toLowerCase();
    if (!value) return defaultValue;
    return value === 'true' || value === '1' || value === 'yes';
  }

  private getNumberInput(name: string, defaultValue: number): number {
    const value = core.getInput(name).trim();
    if (!value) return defaultValue;
    
    const parsed = parseInt(value, 10);
    if (isNaN(parsed)) {
      throw new Error(`Input '${name}' must be a valid number, got: ${value}`);
    }
    return parsed;
  }

  private parseEnvironment(env: string): Environment {
    const validEnvironments: Environment[] = ['sandbox', 'pr', 'dev', 'perf', 'preproduction', 'production'];
    const normalizedEnv = env.toLowerCase() as Environment;
    
    if (!validEnvironments.includes(normalizedEnv)) {
      throw new Error(`Invalid environment '${env}'. Must be one of: ${validEnvironments.join(', ')}`);
    }
    
    return normalizedEnv;
  }

  private isValidRegistryUrl(url: string): boolean {
    try {
      const parsed = new URL(`https://${url}`);
      return parsed.hostname.endsWith('.azurecr.io') || 
             parsed.hostname.includes('azurecr') ||
             /^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]\.azurecr\.io$/.test(parsed.hostname);
    } catch {
      return false;
    }
  }

  private isValidImageName(name: string): boolean {
    // Allow alphanumeric, hyphens, underscores, forward slashes, and dots
    // Must not start with a dot or hyphen
    const imageNameRegex = /^[a-zA-Z0-9][a-zA-Z0-9._/-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$/;
    return imageNameRegex.test(name) && name.length <= 255;
  }

  private isValidTag(tag: string): boolean {
    // Docker tag validation: alphanumeric, dots, dashes, underscores
    // Cannot start with dot or dash, max 128 characters
    const tagRegex = /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/;
    return tagRegex.test(tag) && tag.length <= 128 && tag !== 'latest';
  }

  private isValidTeamName(teamName: string): boolean {
    // Team names should be lowercase, alphanumeric with hyphens
    const teamNameRegex = /^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/;
    return teamNameRegex.test(teamName) && teamName.length >= 2 && teamName.length <= 50;
  }

  private isProductionReadyTag(tag: string): boolean {
    // Check if tag follows semantic versioning pattern
    const semverRegex = /^v?\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?(?:\+[a-zA-Z0-9.-]+)?$/;
    return semverRegex.test(tag);
  }
}