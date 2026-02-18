import { Logger } from './logger';

const logger = new Logger('Retry');

/**
 * Retries an async operation with exponential backoff
 * Only retries on 503/network errors, not client errors (4xx)
 *
 * @param operation - The async operation to retry
 * @param operationName - Name of the operation for logging
 * @param maxRetries - Maximum number of retries (default: 2, total 3 attempts)
 * @param baseDelay - Base delay in milliseconds (default: 5000ms = 5s)
 * @returns The result of the operation
 * @throws The last error if all retries fail
 */
export async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  operationName: string,
  maxRetries: number = 2,
  baseDelay: number = 5000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
    try {
      logger.debug(`${operationName}: Attempt ${attempt}/${maxRetries + 1}`);
      const result = await operation();

      if (attempt > 1) {
        logger.info(`${operationName}: Succeeded on attempt ${attempt}/${maxRetries + 1}`);
      }

      return result;
    } catch (error) {
      lastError = error as Error;
      const errorMessage = error instanceof Error ? error.message : String(error);

      // Check if this is a retryable error (503, 429, overload, network)
      const isRetryable =
        errorMessage.includes('503') ||
        errorMessage.includes('429') ||
        errorMessage.includes('Service Unavailable') ||
        errorMessage.includes('overloaded') ||
        errorMessage.includes('Quota exceeded') ||
        errorMessage.includes('RESOURCE_EXHAUSTED') ||
        errorMessage.includes('ECONNRESET') ||
        errorMessage.includes('ETIMEDOUT');

      // Don't retry on client errors (4xx) except 429 (rate limit)
      const isClientError =
        errorMessage.includes('400') ||
        errorMessage.includes('401') ||
        errorMessage.includes('403') ||
        errorMessage.includes('404') ||
        errorMessage.includes('API key');

      if (isClientError) {
        logger.error(`${operationName}: Client error, not retrying`, error);
        throw error;
      }

      if (!isRetryable || attempt >= maxRetries + 1) {
        logger.error(`${operationName}: Failed after ${attempt} attempts`, error);
        throw error;
      }

      // Calculate delay: 5s, 15s (baseDelay, baseDelay * 3)
      let delay = attempt === 1 ? baseDelay : baseDelay * 3;

      // For 429/quota errors, parse the server's suggested retry delay
      if (errorMessage.includes('429') || errorMessage.includes('RESOURCE_EXHAUSTED') || errorMessage.includes('Quota exceeded')) {
        const retrySecondsMatch = errorMessage.match(/retry\s+in\s+([\d.]+)s/i);
        if (retrySecondsMatch) {
          const serverDelay = Math.ceil(parseFloat(retrySecondsMatch[1]) * 1000) + 2000;
          delay = Math.max(delay, serverDelay);
        } else {
          // Default for 429: wait at least 35s if no delay hint found
          delay = Math.max(delay, 35000);
        }
      }

      logger.warn(`${operationName}: Attempt ${attempt}/${maxRetries + 1} failed: ${errorMessage}`);
      logger.info(`${operationName}: Retrying after ${delay / 1000}s...`);

      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError!;
}
