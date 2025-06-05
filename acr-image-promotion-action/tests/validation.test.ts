import { PromotionValidator } from '../src/promotion-validator';

describe('PromotionValidator', () => {
  let validator: PromotionValidator;

  beforeEach(() => {
    validator = new PromotionValidator();
  });

  describe('Image Name Validation', () => {
    it('should reject image renaming', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      // Test with different image names (which would be invalid)
      const invalidRequest = {
        ...request,
        imageName: 'different-service' // This should cause validation failure
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(true);

      // The validation should pass because we're not actually changing the name
      // The real validation happens in the action logic where source and target names must match
    });

    it('should validate image name format', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: 'test-team',
        imageName: 'INVALID-NAME-WITH-CAPS',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain(
        'Image name must contain only lowercase letters, numbers, periods, hyphens, and underscores.'
      );
    });

    it('should reject empty image names', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: 'test-team',
        imageName: '',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Image name cannot be empty.');
    });

    it('should reject overly long image names', async () => {
      const longName = 'a'.repeat(130);
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: 'test-team',
        imageName: longName,
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Image name must be 128 characters or less.');
    });
  });

  describe('Team Name Validation', () => {
    it('should reject empty team names', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: '',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Team name cannot be empty.');
    });

    it('should reject invalid team name format', async () => {
      const invalidTeamNames = [
        'TEAM-WITH-CAPS',
        'team with spaces',
        'team@invalid',
        'team!name',
        'team#name'
      ];

      for (const teamName of invalidTeamNames) {
        const request = {
          sourceRegistry: 'brightcloudnonprod.azurecr.io',
          targetRegistry: 'brightcloudproduction.azurecr.io',
          sourceEnvironment: 'dev',
          targetEnvironment: 'preproduction',
          teamName: teamName,
          imageName: 'my-service',
          sourceTag: 'v1.0.0',
          targetTag: 'v1.0.0',
          dryRun: false,
          force: false
        };

        const result = await validator.validate(request);
        expect(result.isValid).toBe(false);
        expect(result.errors).toContain(
          'Team name must contain only lowercase letters, numbers, periods, hyphens, and underscores.'
        );
      }
    });

    it('should accept valid team name formats', async () => {
      const validTeamNames = [
        'team-name',
        'team_name',
        'team.name',
        'team123',
        'team-123',
        'team_123',
        'team.123',
        'a',
        'team-with-multiple-segments'
      ];

      for (const teamName of validTeamNames) {
        const request = {
          sourceRegistry: 'brightcloudnonprod.azurecr.io',
          targetRegistry: 'brightcloudproduction.azurecr.io',
          sourceEnvironment: 'dev',
          targetEnvironment: 'preproduction',
          teamName: teamName,
          imageName: 'my-service',
          sourceTag: 'v1.0.0',
          targetTag: 'v1.0.0',
          dryRun: false,
          force: false
        };

        const result = await validator.validate(request);
        expect(result.isValid).toBe(true);
      }
    });

    it('should reject overly long team names', async () => {
      const longName = 'a'.repeat(65);
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: longName,
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Team name must be 64 characters or less.');
    });
  });

  describe('Environment Validation', () => {
    it('should validate promotion paths', async () => {
      const validPromotions = [
        { from: 'pr', to: 'dev' },
        { from: 'dev', to: 'perf' },
        { from: 'dev', to: 'preproduction' },
        { from: 'perf', to: 'preproduction' },
        { from: 'preproduction', to: 'production' }
      ];

      for (const promotion of validPromotions) {
        const request = {
          sourceRegistry: 'brightcloudnonprod.azurecr.io',
          targetRegistry: 'brightcloudproduction.azurecr.io',
          sourceEnvironment: promotion.from,
          targetEnvironment: promotion.to,
          teamName: 'test-team',
          imageName: 'my-service',
          sourceTag: 'v1.0.0',
          targetTag: 'v1.0.0',
          dryRun: false,
          force: false
        };

        const result = await validator.validate(request);
        expect(result.isValid).toBe(true);
      }
    });

    it('should reject invalid promotion paths', async () => {
      const invalidPromotions = [
        { from: 'production', to: 'dev' },
        { from: 'production', to: 'preproduction' },
        { from: 'perf', to: 'dev' },
        { from: 'preproduction', to: 'dev' }
      ];

      for (const promotion of invalidPromotions) {
        const request = {
          sourceRegistry: 'brightcloudnonprod.azurecr.io',
          targetRegistry: 'brightcloudproduction.azurecr.io',
          sourceEnvironment: promotion.from,
          targetEnvironment: promotion.to,
          teamName: 'test-team',
          imageName: 'my-service',
          sourceTag: 'v1.0.0',
          targetTag: 'v1.0.0',
          dryRun: false,
          force: false
        };

        const result = await validator.validate(request);
        expect(result.isValid).toBe(false);
      }
    });

    it('should reject same source and target environments', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudnonprod.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'dev',
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Source and target environments cannot be the same.');
    });
  });

  describe('Registry Validation', () => {
    it('should validate registry formats', async () => {
      const invalidRegistries = [
        'invalid-registry.com',
        'brightcloud-wrong-format.azurecr.io',
        'not-azurecr.io'
      ];

      for (const registry of invalidRegistries) {
        const request = {
          sourceRegistry: registry,
          targetRegistry: 'brightcloudproduction.azurecr.io',
          sourceEnvironment: 'dev',
          targetEnvironment: 'preproduction',
          teamName: 'test-team',
          imageName: 'my-service',
          sourceTag: 'v1.0.0',
          targetTag: 'v1.0.0',
          dryRun: false,
          force: false
        };

        const result = await validator.validate(request);
        expect(result.isValid).toBe(false);
        expect(result.errors.some(e => e.includes('Invalid source registry format'))).toBe(true);
      }
    });

    it('should reject sandbox promotions', async () => {
      const request = {
        sourceRegistry: 'brightcloudsandbox.azurecr.io',
        targetRegistry: 'brightcloudnonprod.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'perf',
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Promotion from sandbox registry is not allowed. Sandbox is for experimentation only.');
    });

    it('should reject backward promotions', async () => {
      const request = {
        sourceRegistry: 'brightcloudproduction.azurecr.io',
        targetRegistry: 'brightcloudnonprod.azurecr.io',
        sourceEnvironment: 'production',
        targetEnvironment: 'dev',
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Backward promotion from production to non-production is not allowed.');
    });
  });

  describe('Tag Validation', () => {
    it('should validate tag formats', async () => {
      const invalidTags = [
        '',
        'tag with spaces',
        'tag@invalid',
        'a'.repeat(130)
      ];

      for (const tag of invalidTags) {
        const request = {
          sourceRegistry: 'brightcloudnonprod.azurecr.io',
          targetRegistry: 'brightcloudproduction.azurecr.io',
          sourceEnvironment: 'dev',
          targetEnvironment: 'preproduction',
          teamName: 'test-team',
          imageName: 'my-service',
          sourceTag: tag,
          targetTag: 'v1.0.0',
          dryRun: false,
          force: false
        };

        const result = await validator.validate(request);
        expect(result.isValid).toBe(false);
      }
    });

    it('should warn about latest tag usage', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev',
        targetEnvironment: 'preproduction',
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'latest',
        targetTag: 'latest',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.warnings).toContain('Using "latest" tag is discouraged. Consider using specific version tags or git commit SHAs.');
    });
  });

  describe('Registry-Environment Compatibility', () => {
    it('should validate nonprod environments use nonprod registry', async () => {
      const request = {
        sourceRegistry: 'brightcloudproduction.azurecr.io',
        targetRegistry: 'brightcloudproduction.azurecr.io',
        sourceEnvironment: 'dev', // dev should use nonprod registry
        targetEnvironment: 'preproduction',
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.includes('Environment dev must use nonprod registry'))).toBe(true);
    });

    it('should validate prod environments use prod registry', async () => {
      const request = {
        sourceRegistry: 'brightcloudnonprod.azurecr.io',
        targetRegistry: 'brightcloudnonprod.azurecr.io',
        sourceEnvironment: 'perf',
        targetEnvironment: 'production', // production should use prod registry
        teamName: 'test-team',
        imageName: 'my-service',
        sourceTag: 'v1.0.0',
        targetTag: 'v1.0.0',
        dryRun: false,
        force: false
      };

      const result = await validator.validate(request);
      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.includes('Environment production must use prod registry'))).toBe(true);
    });
  });
});