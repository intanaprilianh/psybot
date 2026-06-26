const RATE_LIMIT_WINDOW = 60 * 1000;
const MAX_REQUESTS = 10;

const requestMap = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(identifier: string): boolean {
  const now = Date.now();
  const entry = requestMap.get(identifier);

  if (!entry || now > entry.resetAt) {
    requestMap.set(identifier, { count: 1, resetAt: now + RATE_LIMIT_WINDOW });
    return true;
  }

  if (entry.count >= MAX_REQUESTS) return false;

  entry.count++;
  return true;
}
