# Web Angular authoring brief

Approved design: [TDD.md](TDD.md), including W-01 through W-33. Five chapters, numbered 01-05, use exactly the design's phase titles and screen names, matching web-react. Level 201; Web 101 is assumed. Each phase ships the entire application, its immutable contract copy, an isolated Python smoke backend, an exercise starter/solution and a smoke-only verify.json.

## Tier 1 references
- Angular style guide: https://angular.dev/style-guide
- Angular versions: https://angular.dev/reference/versions
- CLI setup: https://angular.dev/tools/cli/setup-local
- Zoneless: https://angular.dev/guide/zoneless
- HTTP interceptors: https://angular.dev/guide/http/interceptors
- Generator maintainer: https://github.com/cyclosproject/ng-openapi-gen
- OIDC maintainer, pinned source: https://github.com/manfredsteyer/angular-oauth2-oidc/tree/22.0.2
- Node: https://nodejs.org/en/download
- npm ci: https://docs.npmjs.com/cli/v11/commands/npm-ci
- tsx maintainer: https://github.com/privatenumber/tsx
- RxJS: https://rxjs.dev/guide/overview
- TypeScript: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html
- RFC 9457, RFC 9110, RFC 7636 and RFC 9700; WCAG 2.2 (linked from TDD).
- Docker: https://docs.docker.com/build/building/multi-stage/
- nginx directives: https://nginx.org/en/docs/http/ngx_http_core_module.html

No Tier 3 sources. No unit suites, ng test, lint, browser automation, production secrets or global CLI installation. Only capstones/web-angular may be edited. All port-using debugging takes the tasksteams lock. Browser-only acceptance remains manual even after smoke PASS.
