import { Injectable } from '@angular/core';
import { OAuthStorage } from 'angular-oauth2-oidc';

// Only these two entries must survive the redirect to Keycloak and back (the PKCE proof).
const transientKeys = new Set(['nonce', 'PKCE_verifier']);

// Tokens, expiry and claims live in a Map (memory only); the proof lives in sessionStorage.
@Injectable({ providedIn: 'root' })
export class SplitStorage implements OAuthStorage {
  private readonly memory = new Map<string, string>();

  getItem(key: string): string | null {
    return transientKeys.has(key) ? sessionStorage.getItem(key) : (this.memory.get(key) ?? null);
  }

  setItem(key: string, value: string): void {
    if (transientKeys.has(key)) {
      sessionStorage.setItem(key, value);
    } else {
      this.memory.set(key, value);
    }
  }

  removeItem(key: string): void {
    if (transientKeys.has(key)) {
      sessionStorage.removeItem(key);
    } else {
      this.memory.delete(key);
    }
  }

  clear(): void {
    this.memory.clear();
    transientKeys.forEach((key) => sessionStorage.removeItem(key));
  }
}
