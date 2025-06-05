export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

export interface PromotionRequest {
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

export class PromotionValidator {
  private readonly VALID_ENVIRONMENTS = ['pr', 'dev', 'perf', 'preproduction', 'production', 'prod'];
  
  private readonly PROMOTION_MATRIX = {
    'pr': ['dev'],
    'dev': ['perf', 'preproduction', 'prod'], // Allow dev->prod for simple pipelines
    'perf': ['preproduction', 'prod'],
    'preproduction': ['production', 'prod'], // Allow both naming conventions
    'production': [], // No promotion from production
    'prod': [] // No promotion from prod (alternative naming)
  };

  private readonly REGISTRY_PATTERNS = {
    sandbox: /^brightcloudsandbox-[a-f0-9]{8}\.azurecr\.io$/,
    nonprod: /^brightcloudnonprod-[a-f0-9]{8}\.azurecr\.io$/,
    prod: /^brightcloudprod-[a-f0-9]{8}\.azurecr\.io$/
  };

  async validate(request: PromotionRequest): Promise<ValidationResult> {
    const errors: string[] = [];
    const warnings: string[] = [];

    // Validate team name consistency (CRITICAL: No renaming allowed)
    this.validateTeamNameConsistency(request, errors);
    
    // Validate image name consistency (CRITICAL: No renaming allowed)
    this.validateImageNameConsistency(request, errors);
    
    // Validate environments
    this.validateEnvironments(request, errors);
    
    // Validate promotion path
    this.validatePromotionPath(request, errors);
    
    // Validate registries
    this.validateRegistries(request, errors);
    
    // Validate tags
    this.validateTags(request, errors, warnings);
    
    // Validate cross-boundary promotions
    this.validateCrossBoundaryPromotion(request, errors);

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }

  private validateTeamNameConsistency(request: PromotionRequest, errors: string[]): void {
    // CRITICAL: Team name must remain exactly the same - no changing teams during promotion
    if (!request.teamName) {
      errors.push('Team name cannot be empty.');
      return;
    }

    // Validate team name format
    const teamNamePattern = /^[a-z0-9]+(?:[._-][a-z0-9]+)*$/;
    if (!teamNamePattern.test(request.teamName)) {
      errors.push('Team name must contain only lowercase letters, numbers, periods, hyphens, and underscores.');
    }

    // Validate team name length
    if (request.teamName.length > 64) {
      errors.push('Team name must be 64 characters or less.');
    }

    if (request.teamName.length < 1) {
      errors.push('Team name cannot be empty.');
    }
  }

  private validateImageNameConsistency(request: PromotionRequest, errors: string[]): void {
    // CRITICAL: Image name must remain exactly the same - no renaming allowed
    const sourceImageName = request.imageName;
    const targetImageName = request.imageName; // Must be identical
    
    if (sourceImageName !== targetImageName) {
      errors.push('Image renaming is not allowed during promotion. Source and target image names must be identical.');
    }

    // Validate image name format
    const imageNamePattern = /^[a-z0-9]+(?:[._-][a-z0-9]+)*$/;
    if (!imageNamePattern.test(request.imageName)) {
      errors.push('Image name must contain only lowercase letters, numbers, periods, hyphens, and underscores.');
    }

    // Validate image name length
    if (request.imageName.length > 128) {
      errors.push('Image name must be 128 characters or less.');
    }

    if (request.imageName.length < 1) {
      errors.push('Image name cannot be empty.');
    }
  }

  private validateEnvironments(request: PromotionRequest, errors: string[]): void {
    if (!this.VALID_ENVIRONMENTS.includes(request.sourceEnvironment)) {
      errors.push(`Invalid source environment: ${request.sourceEnvironment}. Must be one of: ${this.VALID_ENVIRONMENTS.join(', ')}`);
    }

    if (!this.VALID_ENVIRONMENTS.includes(request.targetEnvironment)) {
      errors.push(`Invalid target environment: ${request.targetEnvironment}. Must be one of: ${this.VALID_ENVIRONMENTS.join(', ')}`);
    }

    if (request.sourceEnvironment === request.targetEnvironment) {
      errors.push('Source and target environments cannot be the same.');
    }
  }

  private validatePromotionPath(request: PromotionRequest, errors: string[]): void {
    const allowedTargets = this.PROMOTION_MATRIX[request.sourceEnvironment as keyof typeof this.PROMOTION_MATRIX];
    
    if (!allowedTargets) {
      errors.push(`Promotion from ${request.sourceEnvironment} is not allowed.`);
      return;
    }

    if (!allowedTargets.includes(request.targetEnvironment)) {
      errors.push(`Invalid promotion path: ${request.sourceEnvironment} → ${request.targetEnvironment}. Allowed targets from ${request.sourceEnvironment}: ${allowedTargets.join(', ')}`);
    }
  }

  private validateRegistries(request: PromotionRequest, errors: string[]): void {
    // Validate source registry format
    const sourceRegistryType = this.getRegistryType(request.sourceRegistry);
    if (!sourceRegistryType) {
      errors.push(`Invalid source registry format: ${request.sourceRegistry}`);
    }

    // Validate target registry format
    const targetRegistryType = this.getRegistryType(request.targetRegistry);
    if (!targetRegistryType) {
      errors.push(`Invalid target registry format: ${request.targetRegistry}`);
    }

    // Validate registry compatibility with environments
    if (sourceRegistryType && targetRegistryType) {
      this.validateRegistryEnvironmentCompatibility(
        request.sourceEnvironment,
        request.targetEnvironment,
        sourceRegistryType,
        targetRegistryType,
        errors
      );
    }
  }

  private validateTags(request: PromotionRequest, errors: string[], warnings: string[]): void {
    // Validate tag format
    const tagPattern = /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/;
    
    if (!tagPattern.test(request.sourceTag)) {
      errors.push(`Invalid source tag format: ${request.sourceTag}`);
    }

    if (!tagPattern.test(request.targetTag)) {
      errors.push(`Invalid target tag format: ${request.targetTag}`);
    }

    // Warn about using 'latest' tag
    if (request.sourceTag === 'latest' || request.targetTag === 'latest') {
      warnings.push('Using "latest" tag is discouraged. Consider using specific version tags or git commit SHAs.');
    }

    // Validate tag length
    if (request.sourceTag.length > 128) {
      errors.push('Source tag must be 128 characters or less.');
    }

    if (request.targetTag.length > 128) {
      errors.push('Target tag must be 128 characters or less.');
    }
  }

  private validateCrossBoundaryPromotion(request: PromotionRequest, errors: string[]): void {
    const sourceType = this.getRegistryType(request.sourceRegistry);
    const targetType = this.getRegistryType(request.targetRegistry);

    // Cross-boundary promotion rules
    if (sourceType === 'nonprod' && targetType === 'prod') {
      // Allow promotion from nonprod to prod (this is the main use case)
      return;
    }

    if (sourceType === 'sandbox') {
      errors.push('Promotion from sandbox registry is not allowed. Sandbox is for experimentation only.');
    }

    if (targetType === 'sandbox') {
      errors.push('Promotion to sandbox registry is not allowed. Sandbox is for experimentation only.');
    }

    if (sourceType === 'prod' && targetType === 'nonprod') {
      errors.push('Backward promotion from production to non-production is not allowed.');
    }

    if (sourceType === targetType && sourceType !== 'nonprod') {
      errors.push('Same-registry promotion is only allowed within non-production environments.');
    }
  }

  private validateRegistryEnvironmentCompatibility(
    sourceEnv: string,
    targetEnv: string,
    sourceType: string,
    targetType: string,
    errors: string[]
  ): void {
    // Non-prod environments should use nonprod registry
    const nonProdEnvs = ['pr', 'dev', 'perf'];
    
    if (nonProdEnvs.includes(sourceEnv) && sourceType !== 'nonprod') {
      errors.push(`Environment ${sourceEnv} must use nonprod registry, not ${sourceType}`);
    }

    // Prod environments should use prod registry
    const prodEnvs = ['preproduction', 'production', 'prod'];
    
    if (prodEnvs.includes(targetEnv) && targetType !== 'prod') {
      errors.push(`Environment ${targetEnv} must use prod registry, not ${targetType}`);
    }
  }

  private getRegistryType(registryUrl: string): string | null {
    for (const [type, pattern] of Object.entries(this.REGISTRY_PATTERNS)) {
      if (pattern.test(registryUrl)) {
        return type;
      }
    }
    return null;
  }
}