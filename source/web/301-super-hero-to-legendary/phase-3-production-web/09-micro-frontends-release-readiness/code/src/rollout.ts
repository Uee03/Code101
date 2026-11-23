export interface FlagConfig {
  name: string;
  percent: number;
  killSwitch: boolean;
  allowList: readonly string[];
}

// FNV-1a, 32 bit: small, fast and identical on every platform. It spreads users; it is not a security hash.
export function hash32(text: string): number {
  let hash = 0x811c9dc5;
  for (let index = 0; index < text.length; index += 1) {
    hash ^= text.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

// The flag name is part of the key, so a user who is early for one flag is not early for all of them.
export function bucketOf(userId: string, flagName: string): number {
  return hash32(`${flagName}:${userId}`) % 100;
}

export function isEnabled(flag: FlagConfig, userId: string): boolean {
  if (!Number.isInteger(flag.percent) || flag.percent < 0 || flag.percent > 100) {
    throw new RangeError(`percent must be a whole number from 0 to 100, got ${flag.percent}`);
  }
  if (flag.killSwitch) {
    return false;
  }
  if (flag.allowList.includes(userId)) {
    return true;
  }
  return bucketOf(userId, flag.name) < flag.percent;
}
