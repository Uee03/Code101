# STRIDE for Tasks and Teams

STRIDE names six kinds of threat: Spoofing (pretending to be someone), Tampering (changing data), Repudiation (denying an action), Information disclosure (leaking data), Denial of service (making the system unavailable) and Elevation of privilege (gaining rights not granted).

| Flow or element | Category | Threat | Mitigation in the design | Open question |
|---|---|---|---|---|
| Browser sends the access token to the API | Spoofing | A stolen token is used by someone else | Short token life, refresh token rotation, tokens kept in memory by production web apps, TLS in production | How quickly must a stolen token stop working? |
| Sign-in redirect and code exchange | Spoofing and tampering | A stolen authorization code is redeemed | PKCE with S256, exact redirect addresses, a short code life | Are all redirect addresses reviewed on every change? |
| API sends SQL to PostgreSQL | Tampering and elevation of privilege | An injected statement changes data or the schema | Parameterised queries, stored functions with typed arguments, a limited database role | Is the limited role used in every environment? |
| Audit log | Repudiation | A user or process denies a change, or removes the evidence | A database trigger records the actor; the application role has no update or delete right | Who may read and archive the log? |
| API responses | Information disclosure | Probing ids reveals which objects exist; errors leak internals | 404 for objects the caller cannot see, problem details without stack traces | Are logs scrubbed of personal data? |
| API endpoints | Denial of service | A client or attacker floods the API | Rate limits with 429, a maximum page size, a body size limit | Where do the counters live when there are several instances? |
| Realm file and environment file in Git | Information disclosure and tampering | Real secrets are committed or the realm is changed unnoticed | Only fake local values in the repository; production secrets from a secret store; reviews of the realm file | Is secret scanning running on every push? |
