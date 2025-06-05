// Jest setup file for ACR Image Promotion Action tests

// Mock GitHub Actions core module
jest.mock('@actions/core', () => ({
  getInput: jest.fn(),
  getBooleanInput: jest.fn(),
  setOutput: jest.fn(),
  setFailed: jest.fn(),
  info: jest.fn(),
  warning: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
}));

// Mock GitHub Actions exec module
jest.mock('@actions/exec', () => ({
  exec: jest.fn(),
}));

// Mock Azure SDK modules
jest.mock('@azure/identity', () => ({
  DefaultAzureCredential: jest.fn(),
  WorkloadIdentityCredential: jest.fn(),
}));

jest.mock('@azure/arm-containerregistry', () => ({
  ContainerRegistryManagementClient: jest.fn(),
}));

// Set up environment variables for tests
process.env.GITHUB_ACTIONS = 'true';
process.env.GITHUB_WORKSPACE = '/tmp/test-workspace';
process.env.RUNNER_TEMP = '/tmp';
process.env.RUNNER_TOOL_CACHE = '/tmp/tool-cache';

// Global test utilities
global.console = {
  ...console,
  // Suppress console output during tests unless explicitly needed
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};