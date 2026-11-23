export interface ReleaseReport {
  version: string;
  changes: { breakingApi: boolean; migrations: boolean; featureFlagged: boolean };
  quality: { typecheck: boolean; unitTestsPassed: boolean; e2eSmokePassed: boolean; budgetsPassed: boolean };
  security: {
    auditHighFindings: number;
    cspReportOnlyViolationsLast7d: number;
    secretsScanPassed: boolean;
    actionsPinned: boolean;
  };
  accessibility: { axeCriticalIssues: number; keyboardPathVerified: boolean };
  operations: {
    rollbackPlan: boolean;
    rollbackTestedWithinDays: number | null;
    dashboardLink: string | null;
    onCallAcknowledged: boolean;
    canaryPercent: number;
  };
  documentation: { changelogEntry: boolean; adrLinked: boolean };
}

type Kind = 'string' | 'boolean' | 'number' | 'number|null' | 'string|null';
interface Shape {
  [key: string]: Kind | Shape;
}

// The report arrives from a pipeline: treat it as untrusted data and check every field before use.
const SHAPE: Shape = {
  version: 'string',
  changes: { breakingApi: 'boolean', migrations: 'boolean', featureFlagged: 'boolean' },
  quality: { typecheck: 'boolean', unitTestsPassed: 'boolean', e2eSmokePassed: 'boolean', budgetsPassed: 'boolean' },
  security: {
    auditHighFindings: 'number',
    cspReportOnlyViolationsLast7d: 'number',
    secretsScanPassed: 'boolean',
    actionsPinned: 'boolean',
  },
  accessibility: { axeCriticalIssues: 'number', keyboardPathVerified: 'boolean' },
  operations: {
    rollbackPlan: 'boolean',
    rollbackTestedWithinDays: 'number|null',
    dashboardLink: 'string|null',
    onCallAcknowledged: 'boolean',
    canaryPercent: 'number',
  },
  documentation: { changelogEntry: 'boolean', adrLinked: 'boolean' },
};

function matches(kind: Kind, value: unknown): boolean {
  switch (kind) {
    case 'string':
      return typeof value === 'string';
    case 'boolean':
      return typeof value === 'boolean';
    case 'number':
      return typeof value === 'number' && Number.isFinite(value);
    case 'number|null':
      return value === null || (typeof value === 'number' && Number.isFinite(value));
    case 'string|null':
      return value === null || typeof value === 'string';
  }
}

function check(shape: Shape, value: unknown, path: string, problems: string[]): void {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    problems.push(`${path === '' ? 'report' : path} must be an object`);
    return;
  }
  const record = value as Record<string, unknown>;
  for (const [key, expected] of Object.entries(shape)) {
    const childPath = path === '' ? key : `${path}.${key}`;
    if (typeof expected === 'string') {
      if (!matches(expected, record[key])) {
        problems.push(`${childPath} must be ${expected}`);
      }
    } else {
      check(expected, record[key], childPath, problems);
    }
  }
}

export function parseReport(text: string): ReleaseReport {
  let data: unknown;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error('Release report is not valid JSON');
  }
  const problems: string[] = [];
  check(SHAPE, data, '', problems);
  if (problems.length > 0) {
    throw new Error(`Invalid release report:\n- ${problems.join('\n- ')}`);
  }
  return data as ReleaseReport;
}
