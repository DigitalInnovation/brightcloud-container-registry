export interface PromotionConfig {
  readonly sourceRegistry: string;
  readonly sourceImage: string;
  readonly sourceTag: string;
  readonly targetRegistry: string;
  readonly targetImage?: string;
  readonly targetTag?: string;
  readonly targetEnvironment: Environment;
  readonly teamName: string;
  readonly allowImageRename: boolean;
  readonly dryRun: boolean;
  readonly timeout: number;
}

export interface AzureCredentials {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly tenantId: string;
  readonly subscriptionId: string;
}

export interface RegistryCredentials {
  readonly username: string;
  readonly password: string;
  readonly loginServer: string;
}

export interface PromotionResult {
  readonly success: boolean;
  readonly sourceImage: string;
  readonly targetImage: string;
  readonly digest?: string;
  readonly size?: number;
  readonly error?: Error;
  readonly warnings: string[];
  readonly duration: number;
}

export interface ValidationResult {
  readonly isValid: boolean;
  readonly errors: ValidationError[];
  readonly warnings: string[];
}

export interface ValidationError {
  readonly field: string;
  readonly message: string;
  readonly code: string;
}

export interface ImageManifest {
  readonly mediaType: string;
  readonly schemaVersion: number;
  readonly digest: string;
  readonly size: number;
  readonly architecture?: string;
  readonly os?: string;
  readonly tags: string[];
  readonly createdAt: Date;
  readonly lastUpdated: Date;
}

export interface TeamPermissions {
  readonly teamName: string;
  readonly allowedEnvironments: Environment[];
  readonly allowedRepositories: string[];
  readonly canRenameImages: boolean;
}

export type Environment = 'sandbox' | 'pr' | 'dev' | 'perf' | 'preproduction' | 'production';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export type PromotionType = 
  | 'same-registry'
  | 'cross-registry'
  | 'pr-to-dev'
  | 'to-production'
  | 'sandbox';

export interface Logger {
  debug(message: string, meta?: Record<string, unknown>): void;
  info(message: string, meta?: Record<string, unknown>): void;
  warn(message: string, meta?: Record<string, unknown>): void;
  error(message: string, error?: Error, meta?: Record<string, unknown>): void;
  group(name: string): void;
  groupEnd(): void;
}

export interface RetryConfig {
  readonly maxAttempts: number;
  readonly backoffMs: number;
  readonly backoffMultiplier: number;
  readonly retryableErrors: string[];
}

export interface PromotionMetrics {
  readonly startTime: Date;
  readonly endTime?: Date;
  readonly duration?: number;
  readonly bytesTransferred?: number;
  readonly retryCount: number;
  readonly sourceImageSize?: number;
  readonly targetImageSize?: number;
}

export class PromotionError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly details?: Record<string, unknown>,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = 'PromotionError';
  }
}

export class ValidationError extends Error {
  constructor(
    message: string,
    public readonly field: string,
    public readonly code: string,
    public readonly value?: unknown
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class AuthenticationError extends Error {
  constructor(message: string, public readonly cause?: Error) {
    super(message);
    this.name = 'AuthenticationError';
  }
}

export class NetworkError extends Error {
  constructor(
    message: string,
    public readonly statusCode?: number,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = 'NetworkError';
  }
}