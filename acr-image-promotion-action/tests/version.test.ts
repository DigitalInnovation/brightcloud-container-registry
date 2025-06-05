import { getVersionInfo, logVersionInfo } from '../src/version';

describe('Version Management', () => {
  beforeEach(() => {
    // Clear environment variables
    delete process.env.GITHUB_SHA;
  });

  describe('getVersionInfo', () => {
    it('should return version information with all fields', () => {
      const versionInfo = getVersionInfo();
      
      expect(versionInfo).toHaveProperty('version');
      expect(versionInfo).toHaveProperty('buildDate');
      expect(versionInfo).toHaveProperty('gitHash');
      expect(versionInfo).toHaveProperty('formattedVersion');
    });

    it('should return valid semantic version format', () => {
      const versionInfo = getVersionInfo();
      
      // Should match semver pattern: X.Y.Z
      expect(versionInfo.version).toMatch(/^\d+\.\d+\.\d+$/);
    });

    it('should return numeric build date', () => {
      const versionInfo = getVersionInfo();
      
      expect(versionInfo.buildDate).toMatch(/^\d+$/);
      
      // Should be a reasonable timestamp (after 2024)
      const buildTimestamp = parseInt(versionInfo.buildDate);
      expect(buildTimestamp).toBeGreaterThan(1704067200); // 2024-01-01
    });

    it('should use GITHUB_SHA when available', () => {
      const testSha = 'abcd1234567890abcdef1234567890abcdef1234';
      process.env.GITHUB_SHA = testSha;
      
      const versionInfo = getVersionInfo();
      
      expect(versionInfo.gitHash).toBe(testSha.substring(0, 7));
    });

    it('should use "unknown" git hash when GITHUB_SHA not available', () => {
      const versionInfo = getVersionInfo();
      
      expect(versionInfo.gitHash).toBe('unknown');
    });

    it('should format version according to M&S standards', () => {
      const testSha = 'abcd123';
      process.env.GITHUB_SHA = testSha + '4567890abcdef1234567890';
      
      const versionInfo = getVersionInfo();
      
      // Should match format: version+buildDate+gitHash
      const expectedPattern = new RegExp(`^${versionInfo.version}\\+${versionInfo.buildDate}\\+${testSha}$`);
      expect(versionInfo.formattedVersion).toMatch(expectedPattern);
    });
  });

  describe('logVersionInfo', () => {
    let consoleSpy: jest.SpyInstance;

    beforeEach(() => {
      consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    });

    afterEach(() => {
      consoleSpy.mockRestore();
    });

    it('should log version information in correct format', () => {
      logVersionInfo();

      expect(consoleSpy).toHaveBeenCalledWith(expect.stringMatching(/^Version: \d+\.\d+\.\d+\+\d+\+.+$/));
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringMatching(/^  - Version: \d+\.\d+\.\d+$/));
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringMatching(/^  - Build Date: \d+$/));
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringMatching(/^  - Git Hash: .+$/));
    });

    it('should log all version components', () => {
      logVersionInfo();

      // Should have 4 log entries
      expect(consoleSpy).toHaveBeenCalledTimes(4);
    });
  });

  describe('Integration with package.json', () => {
    it('should read version from package.json if available', () => {
      const versionInfo = getVersionInfo();
      
      // Version should either be from package.json or default to 1.0.0
      expect(versionInfo.version).toMatch(/^\d+\.\d+\.\d+$/);
    });
  });

  describe('M&S Technology Standards Compliance', () => {
    it('should provide RFC3339-compatible build timestamp', () => {
      const versionInfo = getVersionInfo();
      
      // Convert Unix timestamp to Date
      const buildDate = new Date(parseInt(versionInfo.buildDate) * 1000);
      
      // Should be a valid date
      expect(buildDate.getTime()).not.toBeNaN();
      
      // Should be able to convert to ISO string (RFC3339 compatible)
      expect(() => buildDate.toISOString()).not.toThrow();
    });

    it('should provide 7-character git hash for observability', () => {
      const testSha = 'abcdef1234567890abcdef1234567890abcdef12';
      process.env.GITHUB_SHA = testSha;
      
      const versionInfo = getVersionInfo();
      
      expect(versionInfo.gitHash).toHaveLength(7);
      expect(versionInfo.gitHash).toBe('abcdef1');
    });

    it('should include all required metadata for observability', () => {
      const versionInfo = getVersionInfo();
      
      // Check all required fields are present and non-empty
      expect(versionInfo.version).toBeTruthy();
      expect(versionInfo.buildDate).toBeTruthy();
      expect(versionInfo.gitHash).toBeTruthy();
      expect(versionInfo.formattedVersion).toBeTruthy();
      
      // Formatted version should contain all components
      expect(versionInfo.formattedVersion).toContain(versionInfo.version);
      expect(versionInfo.formattedVersion).toContain(versionInfo.buildDate);
      expect(versionInfo.formattedVersion).toContain(versionInfo.gitHash);
    });
  });
});