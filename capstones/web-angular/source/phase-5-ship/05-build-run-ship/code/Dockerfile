FROM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
ARG API_BASE_URL
ARG OIDC_ISSUER
ARG OIDC_CLIENT_ID
RUN node scripts/write-env.mjs && npm run build
FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/web-angular/browser /usr/share/nginx/html
USER 101
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=12 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
