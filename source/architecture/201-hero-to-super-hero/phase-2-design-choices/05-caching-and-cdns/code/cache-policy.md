# Cache policy: Tasks and Teams

Numbers such as lifetimes are decided from measurements. This table names the rule, not the number.

| Data | Who may keep a copy | Where | Freshness rule | What makes it stale | Risk if stale or shared |
|---|---|---|---|---|---|
| Web app files with a content hash in the name | Anyone | Browser and CDN | Keep for a long time; the name changes when the content changes | Nothing; a new build has a new name | None |
| The web app's entry page | Anyone | Browser and CDN | Revalidate on every use | A new release | Users run an old shell |
| One task by id | Only the signed-in user | Browser, private | Revalidate with the ETag every time | Any change raises the version | Low, a stale copy is never shown without a check |
| A list of a user's teams | Only that user | Application cache keyed by user id | Short lifetime chosen from measurements; also remove on a membership change | A membership change | A removed member still sees a team |
| Signing keys from Keycloak | The backend | Backend memory | Keep until an unknown key id appears, then refetch | Key rotation | Wrong keys are trusted or good tokens are refused |
| The audit log | Nobody | Not cached | Always read current data | Not applicable | An admin sees an incomplete trail |
