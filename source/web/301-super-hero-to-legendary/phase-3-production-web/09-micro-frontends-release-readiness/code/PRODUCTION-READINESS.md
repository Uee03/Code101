# Production readiness review

Use this list in the release review. The automated checks in `src/readiness.ts` are the floor;
this list is what people still decide. A blocker is a reason not to ship. Write the evidence next to each answer
(a link, a number you measured, a name), never just "yes".

## Reliability
- [ ] Blocker: every dependency of this release (services, remotes, third-party scripts) has a timeout and a visible fallback.
- [ ] Blocker: a failed remote or API call shows the user a useful message and does not blank the page.
- [ ] A load or soak test covered the new code path, or you wrote down why it did not need one.
- [ ] Retries are limited and only for safe requests; there is a circuit breaker or a budget for repeated failures.

## Performance
- [ ] Blocker: size budgets pass; any raised limit has a reviewed reason and an owner.
- [ ] INP, LCP and CLS from field data were checked for the pages this release touches (your own numbers, with the percentile).
- [ ] No new third-party script without a loading strategy and an owner.

## Security
- [ ] Blocker: no new `unsafe-inline` or `unsafe-eval`, no new wildcard in the CSP; report-only results reviewed.
- [ ] Blocker: tokens are not placed on globals, in URLs, in logs or in storage that scripts can read without a decision record.
- [ ] New dependencies were reviewed by name: exact version, maintainers, install scripts, licence.
- [ ] CORS, redirects and `postMessage` handlers were reviewed if the release touches them.

## Accessibility
- [ ] Blocker: the main task was completed with the keyboard alone and with a screen reader, by a person.
- [ ] Focus is managed when content appears, moves or is removed (dialogs, remotes, route changes).
- [ ] Colour contrast of new tokens is checked per theme; reduced motion and forced colours were tried.

## Data and compatibility
- [ ] Blocker: database changes are backward compatible with the previous release (expand first, contract later).
- [ ] Old browser tabs that still run the previous build keep working against the new server for the overlap period.
- [ ] Hashed static files of the previous release stay available long enough for open tabs.

## Rollout
- [ ] Blocker: a rollback plan exists, names who decides, and was rehearsed for this kind of change.
- [ ] Blocker: the change is behind a flag or starts with a small share of traffic, with a kill switch.
- [ ] The stop conditions are numbers decided before the release (error rate, INP percentile, support tickets).
- [ ] Not released on a Friday afternoon, before a holiday, or when the people who can fix it are away.

## Observability and ownership
- [ ] Blocker: a dashboard shows the stop conditions for this release, and the link is in the release record.
- [ ] Errors from remotes and from the new code are tagged with the release version.
- [ ] On-call acknowledged the release and knows the rollback steps.
- [ ] Support has the user-facing notes and a way to tell which release a user is on.

## Documentation
- [ ] Blocker for breaking changes: a decision record (ADR) explains the trade-off and the migration path.
- [ ] The changelog says what changed for users and for integrators, and what to do about it.
