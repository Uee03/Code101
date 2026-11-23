import { readFileSync } from 'node:fs';

export type TokenType = 'color' | 'dimension' | 'fontFamily';

export interface Token {
  readonly path: readonly string[];
  readonly name: string;
  readonly type: TokenType;
  readonly raw: string;
  readonly description: string | undefined;
}

const TOKEN_TYPES: readonly string[] = ['color', 'dimension', 'fontFamily'];
const REFERENCE = /^\{([^{}]+)\}$/;

function isTokenType(value: unknown): value is TokenType {
  return typeof value === 'string' && TOKEN_TYPES.includes(value);
}

export function loadTokens(file: string): Token[] {
  return flatten(JSON.parse(readFileSync(file, 'utf8')) as unknown, file);
}

// Walk the nested JSON. A node with "$value" is a token; "$type" is inherited from the nearest group.
export function flatten(root: unknown, source: string): Token[] {
  const tokens: Token[] = [];

  const walk = (node: unknown, path: string[], inherited: TokenType | undefined): void => {
    const where = path.join('.') || '(root)';
    if (typeof node !== 'object' || node === null || Array.isArray(node)) {
      throw new Error(`${source}: ${where} must be an object`);
    }
    const record = node as Record<string, unknown>;
    let type = inherited;
    const declared = record['$type'];
    if (declared !== undefined) {
      if (!isTokenType(declared)) {
        throw new Error(`${source}: ${where} has an unknown $type ${String(declared)}`);
      }
      type = declared;
    }
    if ('$value' in record) {
      const value = record['$value'];
      if (typeof value !== 'string') {
        throw new Error(`${source}: ${where} $value must be a string`);
      }
      if (type === undefined) {
        throw new Error(`${source}: ${where} has no $type (set one on the token or its group)`);
      }
      const description = record['$description'];
      tokens.push({
        path,
        name: path.join('-'),
        type,
        raw: value,
        description: typeof description === 'string' ? description : undefined,
      });
      return;
    }
    for (const [key, child] of Object.entries(record)) {
      if (!key.startsWith('$')) {
        walk(child, [...path, key], type);
      }
    }
  };

  walk(root, [], undefined);
  return tokens;
}

// "{palette.white}" becomes "palette-white"; a plain value returns undefined.
export function referenceTarget(raw: string): string | undefined {
  return REFERENCE.exec(raw)?.[1]?.replaceAll('.', '-');
}

// Follow every reference to its final value. Unknown targets, cycles and type changes are errors.
export function resolveAll(tokens: readonly Token[]): Map<string, string> {
  const byName = new Map(tokens.map((token) => [token.name, token] as const));
  const resolved = new Map<string, string>();

  const resolve = (name: string, trail: readonly string[]): string => {
    const cached = resolved.get(name);
    if (cached !== undefined) {
      return cached;
    }
    if (trail.includes(name)) {
      throw new Error(`Circular reference: ${[...trail, name].join(' -> ')}`);
    }
    const token = byName.get(name);
    if (token === undefined) {
      throw new Error(`Unknown token "${name}" referenced from "${trail.at(-1) ?? 'the top level'}"`);
    }
    const target = referenceTarget(token.raw);
    let value = token.raw;
    if (target !== undefined) {
      const targetToken = byName.get(target);
      if (targetToken !== undefined && targetToken.type !== token.type) {
        throw new Error(`Type mismatch: ${name} is ${token.type} but ${target} is ${targetToken.type}`);
      }
      value = resolve(target, [...trail, name]);
    }
    resolved.set(name, value);
    return value;
  };

  for (const token of tokens) {
    resolve(token.name, []);
  }
  return resolved;
}

// Every themed token must exist in every theme, otherwise one theme silently falls back to nothing.
export function assertSameNames(light: readonly Token[], dark: readonly Token[]): void {
  const lightNames = new Set(light.map((token) => token.name));
  const darkNames = new Set(dark.map((token) => token.name));
  const problems = [
    ...[...lightNames].filter((name) => !darkNames.has(name)).map((name) => `${name} is missing in the dark theme`),
    ...[...darkNames].filter((name) => !lightNames.has(name)).map((name) => `${name} is missing in the light theme`),
  ];
  if (problems.length > 0) {
    throw new Error(`Theme mismatch:\n${problems.join('\n')}`);
  }
}
