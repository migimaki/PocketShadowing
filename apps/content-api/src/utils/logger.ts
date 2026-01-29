import type { LogLevel } from '../types/index';

/**
 * Simple logger utility for consistent logging across services
 */
export class Logger {
  private context: string;

  constructor(context: string) {
    this.context = context;
  }

  private log(level: LogLevel, message: string, data?: any): void {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] [${level.toUpperCase()}] [${this.context}] ${message}`;

    console.log(logMessage);
    if (data) {
      console.log(JSON.stringify(data, null, 2));
    }
  }

  info(message: string, data?: any): void {
    this.log('info', message, data);
  }

  warn(message: string, data?: any): void {
    this.log('warn', message, data);
  }

  error(message: string, error?: any): void {
    this.log('error', message);
    if (error) {
      console.error(error);
    }
  }

  debug(message: string, data?: any): void {
    if (process.env.DEBUG === 'true') {
      this.log('debug', message, data);
    }
  }
}
