import { RetryConfig, Logger } from '../types';

export const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  backoffMs: 1000,
  backoffMultiplier: 2,
  retryableErrors: [
    'ECONNRESET',
    'ENOTFOUND',
    'ECONNREFUSED',
    'ETIMEDOUT',
    'NETWORK_ERROR',
    'RATE_LIMITED',
    'SERVER_ERROR'
  ]
};

export class RetryableError extends Error {
  constructor(message: string, public readonly originalError: Error) {
    super(message);
    this.name = 'RetryableError';
  }
}

export async function withRetry<T>(
  operation: () => Promise<T>,
  config: Partial<RetryConfig> = {},
  logger?: Logger
): Promise<T> {
  const retryConfig = { ...DEFAULT_RETRY_CONFIG, ...config };
  let lastError: Error;
  let attempt = 0;

  while (attempt < retryConfig.maxAttempts) {
    attempt++;
    
    try {
      logger?.debug(`Attempt ${attempt}/${retryConfig.maxAttempts}`);
      const result = await operation();
      
      if (attempt > 1) {
        logger?.info(`Operation succeeded after ${attempt} attempts`);
      }
      
      return result;
    } catch (error) {
      lastError = error as Error;
      
      if (attempt === retryConfig.maxAttempts) {
        logger?.error(`Operation failed after ${attempt} attempts`, lastError);
        break;
      }

      if (!isRetryableError(lastError, retryConfig.retryableErrors)) {
        logger?.error(`Non-retryable error encountered`, lastError);
        break;
      }

      const delay = retryConfig.backoffMs * Math.pow(retryConfig.backoffMultiplier, attempt - 1);
      logger?.warn(`Attempt ${attempt} failed, retrying in ${delay}ms`, { error: lastError.message });
      
      await sleep(delay);
    }
  }

  throw lastError!;
}

function isRetryableError(error: Error, retryableErrors: string[]): boolean {
  const errorCode = (error as any).code || error.name || '';
  const errorMessage = error.message.toLowerCase();
  
  return retryableErrors.some(retryableError => 
    errorCode.includes(retryableError) || 
    errorMessage.includes(retryableError.toLowerCase())
  );
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export async function withTimeout<T>(
  operation: Promise<T>,
  timeoutMs: number,
  timeoutMessage = 'Operation timed out'
): Promise<T> {
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => reject(new Error(timeoutMessage)), timeoutMs);
  });

  return Promise.race([operation, timeoutPromise]);
}