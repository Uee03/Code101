# Connection inventory: local Tasks and Teams stack

| From | To | Protocol and port | Initiated by | Credential |
|---|---|---|---|---|
| Browser | Web dev server | HTTP, 4200 or 5173 | Browser | none, the app files are public |
| Browser | Keycloak | HTTP, 8180 on 127.0.0.1 | Browser | username and password typed on the Keycloak page |
| Browser | Backend API | HTTP, 8000 | Browser | bearer access token |
| Backend API | PostgreSQL | SQL over TCP, 5432 on 127.0.0.1 | Backend API | database role tasks_app, secret kept in a git-ignored .env |
| Backend API | Keycloak | HTTP, 8180, signing keys (JWKS) | Backend API | none, the keys are public |

Not shown: HTTPS, a gateway, a cache, mobile clients and any production hosting. They are proposals or other views.
