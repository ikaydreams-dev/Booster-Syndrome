export interface RetryOptions {
  maxAttempts: number;
  delay: number;
  backoffMultiplier?: number;
  maxDelay?: number;
  retryableErrors?: string[];
  onRetry?: (attempt: number, error: Error) => void;
}

export class RetryableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RetryableError';
  }
}

export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions
): Promise<T> {
  const {
    maxAttempts,
    delay,
    backoffMultiplier = 2,
    maxDelay = 30000,
    retryableErrors = [],
    onRetry,
  } = options;

  let lastError: Error;
  let currentDelay = delay;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      if (attempt === maxAttempts) {
        throw lastError;
      }

      if (!isRetryable(lastError, retryableErrors)) {
        throw lastError;
      }

      if (onRetry) {
        onRetry(attempt, lastError);
      }

      await sleep(currentDelay);

      currentDelay = Math.min(currentDelay * backoffMultiplier, maxDelay);
    }
  }

  throw lastError!;
}

export async function retryWithExponentialBackoff<T>(
  fn: () => Promise<T>,
  maxAttempts: number = 3
): Promise<T> {
  return retry(fn, {
    maxAttempts,
    delay: 1000,
    backoffMultiplier: 2,
    maxDelay: 10000,
  });
}

function isRetryable(error: Error, retryableErrors: string[]): boolean {
  if (error instanceof RetryableError) {
    return true;
  }

  if (retryableErrors.length === 0) {
    return true;
  }

  return retryableErrors.some((errorType) => error.name === errorType);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export class RetryPolicy {
  private options: RetryOptions;

  constructor(options: RetryOptions) {
    this.options = options;
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    return retry(fn, this.options);
  }
}

export const defaultRetryPolicy = new RetryPolicy({
  maxAttempts: 3,
  delay: 1000,
  backoffMultiplier: 2,
  maxDelay: 10000,
});

export const aggressiveRetryPolicy = new RetryPolicy({
  maxAttempts: 5,
  delay: 500,
  backoffMultiplier: 1.5,
  maxDelay: 5000,
});

export const conservativeRetryPolicy = new RetryPolicy({
  maxAttempts: 2,
  delay: 2000,
  backoffMultiplier: 3,
  maxDelay: 30000,
});
