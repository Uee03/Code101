---
name: curating-links
description: 'Tiers, checks and prunes the source links for Code101 using docs/LINKS.md and scripts/check_links.py. Use when adding a link, checking dead links, ranking sources, or when the user says sort the links, remove useless links, or check references.'
---

# Curating links

**Best model:** Quick tier (GPT-6 Luna) via the Link Curator.

| Tier | Meaning | Use |
|------|---------|-----|
| 1 | Official or standards docs | Cite in lessons; source of truth for rules and versions |
| 2 | Respected secondary source | Explanations and cross-checks; confirm facts against Tier 1 |
| 3 | Optional or niche | Only when a lesson needs the angle |
| drop | Medium or Dev.to listicle, marketing, duplicate of Tier 1, paywalled, dated, login-walled | Do not cite |

## Steps

1. Decide the tier; no tier, no entry. Record topic, URL, status, and which track and level it feeds in `docs/LINKS.md`.
2. Run `python scripts/check_links.py` (all) or `python scripts/check_links.py --track python`. 403 from a script means the site blocks bots: open it in a browser before citing. Replace dead links with a Tier 1 equivalent or an archive link.
3. Each track `_BRIEF.md` copies only its own links (maximum 10). Authors never load `docs/LINKS.md`.
4. Prefer official docs of the exact version being taught over any article.
