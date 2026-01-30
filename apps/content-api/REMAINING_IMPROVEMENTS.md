# Remaining Reliability Improvements

## Overview

8 out of 10 code review issues have been successfully fixed. The remaining 2 issues require additional infrastructure setup and are documented here for future implementation.

---

## Issue #8: Rate Limiting for Manual API Triggers

**Status:** Not Implemented (Requires Upstash Redis)
**Priority:** Medium
**Estimated Time:** 30 minutes + infrastructure setup

### Problem
Manual API triggers (via `x-api-secret`) have no rate limiting, allowing potential API quota exhaustion if the secret is compromised.

### Solution: Upstash Redis Rate Limiting

#### 1. Setup Upstash Account
```bash
# Visit https://upstash.com
# Create account and new Redis database
# Note the UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN
```

#### 2. Install Dependencies
```bash
cd apps/content-api
npm install @upstash/ratelimit @upstash/redis
```

#### 3. Add Environment Variables
```bash
# In Vercel dashboard or .env
UPSTASH_REDIS_REST_URL=https://your-db.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_token_here
```

#### 4. Implementation Code

Add to `apps/content-api/api/generate-content.ts`:

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

// Initialize rate limiter (after imports)
const ratelimit = process.env.UPSTASH_REDIS_REST_URL
  ? new Ratelimit({
      redis: Redis.fromEnv(),
      limiter: Ratelimit.slidingWindow(5, '1 h'), // 5 requests per hour
      analytics: true,
    })
  : null;

// Add before processing (after authentication)
if (!isCronJob && ratelimit) {
  const identifier = req.headers['x-forwarded-for'] as string || 'unknown';
  const { success, limit, remaining, reset } = await ratelimit.limit(identifier);

  if (!success) {
    logger.warn('Rate limit exceeded', {
      identifier,
      limit,
      remaining,
      resetAt: new Date(reset).toISOString(),
    });

    res.status(429).json({
      success: false,
      error: 'Rate limit exceeded',
      message: `Too many requests. Limit: ${limit}/hour. Try again at ${new Date(reset).toISOString()}`,
      retryAfter: Math.ceil((reset - Date.now()) / 1000),
    } as GenerationResult);
    return;
  }

  logger.info('Rate limit check passed', { remaining, limit });
}
```

#### 5. Testing
```bash
# Test rate limit
for i in {1..6}; do
  curl -X POST http://localhost:3000/api/generate-content \
    -H "x-api-secret: your_secret" \
    -d '{"series_ids": ["test"]}'
  sleep 1
done

# 6th request should return 429 Too Many Requests
```

### Benefits
- ✅ Prevents API quota exhaustion
- ✅ Protects against compromised secrets
- ✅ Tracks usage per IP address
- ✅ Automatic reset after time window

### Alternative: Without Upstash
If you don't want to use Upstash, implement a simple in-memory counter (Note: resets on each deployment):

```typescript
const requestCounts = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(identifier: string, limit = 5, windowMs = 3600000): boolean {
  const now = Date.now();
  const entry = requestCounts.get(identifier);

  if (!entry || now > entry.resetAt) {
    requestCounts.set(identifier, { count: 1, resetAt: now + windowMs });
    return true;
  }

  if (entry.count >= limit) {
    return false;
  }

  entry.count++;
  return true;
}
```

---

## Issue #10: Circuit Breaker for External API Failures

**Status:** Not Implemented (Requires Library)
**Priority:** Low
**Estimated Time:** 45 minutes

### Problem
If Gemini/TTS APIs are down, the function will retry indefinitely, wasting execution time and blocking other cron jobs.

### Solution: Circuit Breaker Pattern with Opossum

#### 1. Install Dependencies
```bash
cd apps/content-api
npm install opossum
npm install --save-dev @types/opossum
```

#### 2. Create Circuit Breaker Utility

Create `apps/content-api/src/utils/circuit-breaker.ts`:

```typescript
import CircuitBreaker from 'opossum';
import { Logger } from './logger';

const logger = new Logger('CircuitBreaker');

export interface CircuitBreakerOptions {
  timeout?: number;
  errorThresholdPercentage?: number;
  resetTimeout?: number;
  name: string;
}

export function createCircuitBreaker<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  options: CircuitBreakerOptions
): CircuitBreaker<Parameters<T>, Awaited<ReturnType<T>>> {
  const breaker = new CircuitBreaker(fn, {
    timeout: options.timeout || 30000, // 30s
    errorThresholdPercentage: options.errorThresholdPercentage || 50, // Open after 50% failures
    resetTimeout: options.resetTimeout || 60000, // Try again after 60s
  });

  // Event listeners for monitoring
  breaker.on('open', () => {
    logger.error(`Circuit breaker OPEN: ${options.name} - too many failures`, {
      name: options.name,
      stats: breaker.stats,
    });
  });

  breaker.on('halfOpen', () => {
    logger.warn(`Circuit breaker HALF-OPEN: ${options.name} - testing recovery`, {
      name: options.name,
    });
  });

  breaker.on('close', () => {
    logger.info(`Circuit breaker CLOSED: ${options.name} - service recovered`, {
      name: options.name,
    });
  });

  breaker.on('fallback', (result) => {
    logger.warn(`Circuit breaker FALLBACK: ${options.name}`, {
      name: options.name,
      fallbackResult: result,
    });
  });

  return breaker;
}
```

#### 3. Wrap External API Calls

Update `apps/content-api/src/services/gemini.ts`:

```typescript
import { createCircuitBreaker } from '../utils/circuit-breaker';

// Wrap the API call
const geminiBreaker = createCircuitBreaker(
  async (prompt: string) => {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
    const result = await model.generateContent(prompt);
    return result.response.text();
  },
  {
    name: 'Gemini AI',
    timeout: 30000,
    errorThresholdPercentage: 50,
    resetTimeout: 60000,
  }
);

// Add fallback
geminiBreaker.fallback(() => {
  throw new Error('Gemini AI circuit breaker is OPEN - service unavailable');
});

// Use in functions
export async function generateSpecialDayContent(date: Date, series?: Series): Promise<SummarizedContent> {
  try {
    const text = await geminiBreaker.fire(prompt);
    // ... rest of logic
  } catch (error) {
    if (error.message.includes('circuit breaker is OPEN')) {
      // Handle gracefully - maybe use cached content or skip
      logger.error('Gemini service is down, skipping generation');
      throw error;
    }
    // ... handle other errors
  }
}
```

#### 4. Monitoring

Add circuit breaker health endpoint:

```typescript
// apps/content-api/api/health.ts
import type { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const health = {
    status: 'ok',
    circuitBreakers: {
      gemini: geminiBreaker.opened ? 'OPEN' : 'CLOSED',
      tts: ttsBreaker.opened ? 'OPEN' : 'CLOSED',
    },
    stats: {
      gemini: geminiBreaker.stats,
      tts: ttsBreaker.stats,
    },
  };

  res.status(200).json(health);
}
```

### Benefits
- ✅ Prevents cascading failures
- ✅ Automatic recovery detection
- ✅ Saves execution time during outages
- ✅ Better error reporting

### Alternative: Simple Implementation
Without opossum, implement a basic circuit breaker:

```typescript
class SimpleCircuitBreaker {
  private failures = 0;
  private lastFailureTime = 0;
  private readonly threshold = 3;
  private readonly timeout = 60000; // 60s

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.isOpen()) {
      throw new Error('Circuit breaker is OPEN');
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private isOpen(): boolean {
    if (this.failures >= this.threshold) {
      const timeSinceFailure = Date.now() - this.lastFailureTime;
      return timeSinceFailure < this.timeout;
    }
    return false;
  }

  private onSuccess(): void {
    this.failures = 0;
  }

  private onFailure(): void {
    this.failures++;
    this.lastFailureTime = Date.now();
  }
}
```

---

## Priority Recommendation

1. **Rate Limiting (#8):** Implement if you plan to share the API secret with others or if the API is exposed publicly.

2. **Circuit Breaker (#10):** Implement if you experience frequent external API outages or want better resilience.

Both improvements are optional since:
- The current retry logic (in `retry.ts`) already handles transient failures
- Rate limiting is less critical if the API secret is well-protected
- Circuit breakers add complexity that may not be needed for a small-scale project

---

## Questions?

If you decide to implement these:
1. Set up infrastructure (Upstash for #8)
2. Follow the code examples above
3. Test thoroughly before deploying
4. Monitor logs for circuit breaker events

**Need help?** Refer to the documentation:
- Upstash: https://upstash.com/docs/redis/overall/getstarted
- Opossum: https://nodeshift.dev/opossum/
