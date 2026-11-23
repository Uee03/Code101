import type { ReleaseReport } from './report.js';

export type Severity = 'blocker' | 'warning';

export interface Check {
  id: string;
  severity: Severity;
  title: string;
  passes: (report: ReleaseReport) => boolean;
}

// Automated checks are the floor, not the ceiling: PRODUCTION-READINESS.md lists what people still review.
export const CHECKS: readonly Check[] = [
  {
    id: 'quality.tests',
    severity: 'blocker',
    title: 'Type check, unit tests and end-to-end smoke tests pass',
    passes: (r) => r.quality.typecheck && r.quality.unitTestsPassed && r.quality.e2eSmokePassed,
  },
  { id: 'quality.budgets', severity: 'blocker', title: 'Performance budgets pass', passes: (r) => r.quality.budgetsPassed },
  {
    id: 'security.audit',
    severity: 'blocker',
    title: 'No high or critical dependency findings',
    passes: (r) => r.security.auditHighFindings === 0,
  },
  { id: 'security.secrets', severity: 'blocker', title: 'Secret scan is clean', passes: (r) => r.security.secretsScanPassed },
  {
    id: 'security.actions-pinned',
    severity: 'warning',
    title: 'CI actions are pinned to commit SHAs',
    passes: (r) => r.security.actionsPinned,
  },
  {
    id: 'security.csp-reports',
    severity: 'warning',
    title: 'No report-only CSP violations in the last 7 days',
    passes: (r) => r.security.cspReportOnlyViolationsLast7d === 0,
  },
  {
    id: 'a11y.axe',
    severity: 'blocker',
    title: 'No critical automated accessibility issues',
    passes: (r) => r.accessibility.axeCriticalIssues === 0,
  },
  {
    id: 'a11y.keyboard',
    severity: 'blocker',
    title: 'The main task works with the keyboard alone',
    passes: (r) => r.accessibility.keyboardPathVerified,
  },
  { id: 'ops.rollback-plan', severity: 'blocker', title: 'A rollback plan exists', passes: (r) => r.operations.rollbackPlan },
  {
    id: 'ops.rollback-tested',
    severity: 'warning',
    title: 'Rollback was tested in the last 90 days',
    passes: (r) => r.operations.rollbackTestedWithinDays !== null && r.operations.rollbackTestedWithinDays <= 90,
  },
  { id: 'ops.dashboard', severity: 'blocker', title: 'A dashboard link is attached', passes: (r) => r.operations.dashboardLink !== null },
  { id: 'ops.oncall', severity: 'blocker', title: 'On-call acknowledged the release', passes: (r) => r.operations.onCallAcknowledged },
  {
    id: 'ops.canary',
    severity: 'blocker',
    title: 'Unflagged changes start at 10 percent or less',
    passes: (r) => r.changes.featureFlagged || (r.operations.canaryPercent >= 1 && r.operations.canaryPercent <= 10),
  },
  {
    id: 'docs.breaking-adr',
    severity: 'blocker',
    title: 'Breaking API changes link a decision record',
    passes: (r) => !r.changes.breakingApi || r.documentation.adrLinked,
  },
  { id: 'docs.changelog', severity: 'warning', title: 'A changelog entry exists', passes: (r) => r.documentation.changelogEntry },
];

export interface Finding {
  check: Check;
  passed: boolean;
}

export function evaluate(report: ReleaseReport): Finding[] {
  return CHECKS.map((check) => ({ check, passed: check.passes(report) }));
}

export interface Summary {
  lines: string[];
  blockers: number;
  warnings: number;
  ready: boolean;
}

export function summarize(findings: readonly Finding[], version: string): Summary {
  const lines = findings.map(({ check, passed }) => {
    const status = passed ? 'PASS' : check.severity === 'blocker' ? 'FAIL' : 'WARN';
    return `${status} ${check.id}: ${check.title}`;
  });
  const blockers = findings.filter((finding) => !finding.passed && finding.check.severity === 'blocker').length;
  const warnings = findings.filter((finding) => !finding.passed && finding.check.severity === 'warning').length;
  const ready = blockers === 0;
  lines.push(`${blockers} blocker(s) failing, ${warnings} warning(s). ${ready ? 'Ready' : 'NOT ready'} to release ${version}`);
  return { lines, blockers, warnings, ready };
}
