# Architecture package: Tasks and Teams platform

Owner: Platform maintainers. Date: 2026-11-23. Status: teaching example built from capstones/platform/TDD.md. Proposals are marked as proposals in each file.

## Read in this order
1. arc42.md: the twelve sections in short form (lesson 08).
2. diagrams/context.mmd: who uses the platform and what it depends on (C4 level 1).
3. diagrams/containers.mmd: the applications and the database (C4 level 2).
4. diagrams/components-backend.mmd: the parts inside the backend API (C4 level 3).
5. adr/: decisions with options and costs (0001, 0002, 0003).
6. quality/scenarios.md and quality/risks.md: what must hold and what may go wrong (lesson 09).
7. quality/traceability.md: how the above connect.

## Boundary choice
The context and container views treat Keycloak as an external system. The platform TDD draws it inside the container boundary. Both are valid; this package states its choice so readers do not compare unlike pictures.

## Not covered
Mobile client internals, the full schema, production hosting and any feature marked as a proposal elsewhere.
