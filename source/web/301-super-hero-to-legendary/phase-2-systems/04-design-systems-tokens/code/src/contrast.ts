export interface Pair {
  readonly foreground: string;
  readonly background: string;
}

function channel(hex: string, offset: number): number {
  const value = Number.parseInt(hex.slice(offset, offset + 2), 16) / 255;
  // sRGB to linear light. 0.04045 is the sRGB threshold; WCAG 2.x text says 0.03928, which gives the same result for 8-bit values.
  return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
}

// WCAG relative luminance of a #rrggbb colour.
export function luminance(hex: string): number {
  if (!/^#[0-9a-f]{6}$/i.test(hex)) {
    throw new Error(`Expected a colour like #rrggbb, got "${hex}"`);
  }
  return 0.2126 * channel(hex, 1) + 0.7152 * channel(hex, 3) + 0.0722 * channel(hex, 5);
}

export function contrastRatio(first: string, second: string): number {
  const a = luminance(first);
  const b = luminance(second);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

export function checkPairs(
  theme: string,
  resolved: ReadonlyMap<string, string>,
  pairs: readonly Pair[],
  minimum: number,
): string[] {
  const failures: string[] = [];
  for (const { foreground, background } of pairs) {
    const fg = resolved.get(foreground);
    const bg = resolved.get(background);
    if (fg === undefined || bg === undefined) {
      failures.push(`${theme}: unknown token in pair ${foreground} on ${background}`);
      continue;
    }
    const ratio = contrastRatio(fg, bg);
    if (ratio < minimum) {
      failures.push(`${theme}: ${foreground} on ${background} is ${ratio.toFixed(2)}:1 (minimum ${minimum}:1)`);
    }
  }
  return failures;
}
