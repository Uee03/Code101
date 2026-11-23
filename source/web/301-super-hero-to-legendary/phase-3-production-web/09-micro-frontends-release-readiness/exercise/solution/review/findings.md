# Review of pull request 4217: one possible answer

Decision: **block** until the blockers are fixed. The release can still happen, later, in smaller steps.

| # | Finding | Severity | Why it matters | Fix or condition | Automated check |
|---|---|---|---|---|---|
| 1 | "No canary", flag at 100 percent at release time | Blocker | Every user gets the new code at once; a defect becomes an incident for everyone | Start the flag at 1 to 5 percent, watch agreed stop conditions, ramp in steps | `ops.canary` (when the report says the change is not flagged and the share is above 10) |
| 2 | Rollback is "redeploy the previous commit" while migration 0042 drops a column and has no down migration | Blocker | The previous code needs `legacy_position` and `position`; after the migration it breaks, so rollback does not work | Expand and contract: add `sort_key` and keep the old column for at least one release; write and rehearse the rollback | `ops.rollback-plan` only checks that a plan exists, not that it works: this needs a person |
| 3 | The API response renames `position` to `sortKey`; mobile clients are told "next sprint" | Blocker | Old clients break the moment the server deploys | Additive change: return both fields during a deprecation period, announce with `Deprecation` and `Sunset` headers, or version the API | `docs.breaking-adr` (requires a decision record) and a contract-diff check in CI |
| 4 | `import(url)` with no `try`/`catch` and no timeout: "it will not fail" | Blocker | A slow or failing remote blanks or hangs the whole page | Load through `loadRemote`: timeout, contract check, fallback UI | No (code review); the pattern is `loader.ts` |
| 5 | The access token is passed through `window.__ACCESS_TOKEN__` | Blocker | Every script on the page, including every remote and every third party, can read it | Give the remote an API client or a function that adds the token, not the token; or use a cookie-based backend for frontend | No (security review); lesson 08 |
| 6 | CSP gains `'unsafe-inline'` and a host | Blocker | Injected inline scripts now run, and the host becomes a trusted source for any script it serves | Remove inline bootstrap from the remote or give it a nonce or hash; keep `strict-dynamic` | `security.csp-reports` only warns on report-only violations; `lint` in lesson 08 would flag it |
| 7 | New dependency with a `^` range and a `postinstall` script | Blocker | A new release can enter silently, and install scripts run code on every developer machine and CI run | Exact version, review the package by name, no install script (download fonts at build time on purpose, from your own code) | `check-package-policy.mjs` (lesson 08) |
| 8 | Performance budget raised to make CI green | Warning to blocker | The check passes because the limit moved, not because the page improved | Treat a raised budget like a code change: owner, reason, a plan to lower it again, evidence from the field | The budget check cannot catch this: it is a policy decision; add a review rule that `budgets.json` changes need a performance owner |
| 9 | axe not run; dialog with no focus management | Blocker | Keyboard and screen reader users can be locked out of the main task | Run axe, move focus into the dialog, trap it, return it on close, test with the keyboard and one screen reader | `a11y.axe` and `a11y.keyboard` (they fail in `release-candidate-2.json`) |
| 10 | Friday 16:30, dashboard "after", on-call "on Monday", changelog later | Blocker (dashboard, on-call), warning (changelog) | Nobody can see a problem or fix it quickly, and the release lands before the weekend | Move to a weekday morning; dashboard and on-call acknowledgement come first | `ops.dashboard`, `ops.oncall`, `docs.changelog` |

## Questions to ask the author first
1. What are the numbers that make you stop the rollout, and where can I see them?
2. If we must roll back at 17:00 on Friday, what exactly do you do, and has anyone done it for a change like this?
3. Which parts of this pull request could ship alone, today, without any of the risks above?

## What the checker prints for `data/release-candidate-2.json`
It reports 7 failing blockers and 3 warnings, which matches findings 1, 3 (documentation), 9 and 10 plus the rollback plan. Findings 2 (rollback that does not work), 4, 5, 6 (as a risk), 7 and 8 are invisible to it: automated checks verify that evidence exists, people judge whether the evidence is good.
