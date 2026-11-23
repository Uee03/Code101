# Runbook: <alert or symptom name>

Owner: <team and on-call rotation>
Last tested: <date of the last drill or real use>
Severity guide: S1 customers cannot use the service; S2 degraded; S3 no user impact yet.

## Symptoms
- Alert names and dashboards that point here.
- What a user sees.

## Impact and urgency
- Who is affected and how badly.
- What gets worse if nobody acts in 15 minutes.

## First checks (2 minutes)
1. Is it real? Open the dashboard and compare with the alert.
2. What changed recently? Releases, config, certificates, traffic.
3. Is a dependency down? Check its status first.

## Mitigate (stop the harm before finding the cause)
1. The safest action first (for example roll back the last release).
2. The next action, with the exact command.
3. Stop and escalate if none of these works within 30 minutes.

## Verify recovery
- The metric or check that proves it is fixed.
- How long to watch before closing the incident.

## Escalate
- Who to call and when, with the contact method.

## Afterwards
- Open a blameless review within five working days.
- Update this runbook with what was missing.
