import { Logger } from './logger';

const logger = new Logger('RateLimiter');

/**
 * Rate limiter for Gemini TTS API
 * Enforces the 10 requests per minute limit with configurable safety buffer
 */
export class RateLimiter {
  private lastCallTime: number = 0;
  private readonly minDelayMs: number;
  private readonly requestsPerMinute: number;

  /**
   * Creates a rate limiter instance
   * @param requestsPerMinute - Maximum requests allowed per minute (default: 10 for Gemini TTS)
   * @param safetyBufferMs - Additional delay buffer for safety (default: 1000ms)
   */
  constructor(requestsPerMinute: number = 10, safetyBufferMs: number = 1000) {
    this.requestsPerMinute = requestsPerMinute;
    // Calculate minimum delay: 60000ms / requests per minute + safety buffer
    // For 10 req/min: 60000/10 = 6000ms + 1000ms buffer = 7000ms
    this.minDelayMs = Math.floor(60000 / requestsPerMinute) + safetyBufferMs;

    logger.info('Rate limiter initialized', {
      requestsPerMinute,
      minDelayMs: this.minDelayMs,
      safetyBufferMs
    });
  }

  /**
   * Waits if necessary to ensure rate limit compliance
   * Call this before each API request
   */
  async waitIfNeeded(): Promise<void> {
    const now = Date.now();
    const timeSinceLastCall = now - this.lastCallTime;

    if (this.lastCallTime > 0 && timeSinceLastCall < this.minDelayMs) {
      const waitTime = this.minDelayMs - timeSinceLastCall;
      logger.info('Rate limiting: waiting before next TTS call', {
        waitTimeMs: waitTime,
        waitTimeSec: (waitTime / 1000).toFixed(1),
        timeSinceLastCallMs: timeSinceLastCall
      });
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }

    this.lastCallTime = Date.now();
  }

  /**
   * Resets the rate limiter state
   * Useful for testing or when starting a new batch
   */
  reset(): void {
    this.lastCallTime = 0;
    logger.debug('Rate limiter reset');
  }

  /**
   * Gets the minimum delay in milliseconds between calls
   */
  getMinDelayMs(): number {
    return this.minDelayMs;
  }

  /**
   * Gets the time since last call in milliseconds
   */
  getTimeSinceLastCall(): number {
    if (this.lastCallTime === 0) {
      return Infinity;
    }
    return Date.now() - this.lastCallTime;
  }
}
