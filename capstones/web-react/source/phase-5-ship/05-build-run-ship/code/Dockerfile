# syntax=docker/dockerfile:1
FROM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
ARG VITE_API_BASE_URL=http://localhost:8000
ARG VITE_OIDC_AUTHORITY=http://localhost:8180/realms/tasksteams
ARG VITE_OIDC_CLIENT_ID=tasks-web
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL     VITE_OIDC_AUTHORITY=$VITE_OIDC_AUTHORITY     VITE_OIDC_CLIENT_ID=$VITE_OIDC_CLIENT_ID
RUN npm run build
FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
USER 101:101
EXPOSE 8080
HEALTHCHECK --interval=3s --timeout=3s --start-period=5s --retries=10     CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
