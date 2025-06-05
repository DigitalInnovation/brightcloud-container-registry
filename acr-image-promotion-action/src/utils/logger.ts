import * as core from '@actions/core';
import { Logger, LogLevel } from '../types';

export class ActionLogger implements Logger {
  private readonly groupStack: string[] = [];

  constructor(private readonly level: LogLevel = 'info') {}

  debug(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog('debug')) {
      const formattedMessage = this.formatMessage(message, meta);
      core.debug(formattedMessage);
    }
  }

  info(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog('info')) {
      const formattedMessage = this.formatMessage(message, meta);
      core.info(formattedMessage);
    }
  }

  warn(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog('warn')) {
      const formattedMessage = this.formatMessage(message, meta);
      core.warning(formattedMessage);
    }
  }

  error(message: string, error?: Error, meta?: Record<string, unknown>): void {
    if (this.shouldLog('error')) {
      const errorDetails = error ? {
        name: error.name,
        message: error.message,
        stack: error.stack,
        ...(error as any).details
      } : undefined;

      const allMeta = { ...meta, error: errorDetails };
      const formattedMessage = this.formatMessage(message, allMeta);
      core.error(formattedMessage);
    }
  }

  group(name: string): void {
    this.groupStack.push(name);
    core.startGroup(name);
  }

  groupEnd(): void {
    if (this.groupStack.length > 0) {
      this.groupStack.pop();
      core.endGroup();
    }
  }

  private shouldLog(level: LogLevel): boolean {
    const levels: Record<LogLevel, number> = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3
    };

    return levels[level] >= levels[this.level];
  }

  private formatMessage(message: string, meta?: Record<string, unknown>): string {
    const timestamp = new Date().toISOString();
    const prefix = this.groupStack.length > 0 ? `[${this.groupStack.join(' > ')}] ` : '';
    
    if (meta && Object.keys(meta).length > 0) {
      const metaString = JSON.stringify(meta, this.replacer, 2);
      return `${timestamp} - ${prefix}${message}\nMetadata: ${metaString}`;
    }
    
    return `${timestamp} - ${prefix}${message}`;
  }

  private replacer(key: string, value: unknown): unknown {
    // Mask sensitive information
    const sensitiveKeys = ['password', 'secret', 'token', 'key', 'credential'];
    if (sensitiveKeys.some(sensitive => key.toLowerCase().includes(sensitive))) {
      return '[REDACTED]';
    }
    
    // Handle errors
    if (value instanceof Error) {
      return {
        name: value.name,
        message: value.message,
        stack: value.stack
      };
    }
    
    return value;
  }
}

export const createLogger = (level: LogLevel = 'info'): Logger => {
  return new ActionLogger(level);
};