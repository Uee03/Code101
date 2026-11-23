# syntax=docker/dockerfile:1

# Stage 1: the SDK image plus the C toolchain that Native AOT needs to link the executable.
FROM mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24 AS build
RUN apk add --no-cache clang build-base zlib-dev
WORKDIR /src

# Restore first, on its own layer: it only re-runs when the project, the SDK pin or the build settings change.
COPY global.json Directory.Build.props .editorconfig ./
COPY src/Inventory.Api/Inventory.Api.csproj src/Inventory.Api/
RUN dotnet restore src/Inventory.Api/Inventory.Api.csproj -r linux-musl-x64

COPY src/Inventory.Api/ src/Inventory.Api/
RUN dotnet publish src/Inventory.Api/Inventory.Api.csproj -c Release -r linux-musl-x64 --no-restore -o /app/publish

# Stage 2: only what a native executable needs to run (musl libc and a few libraries; no .NET runtime, no SDK).
FROM mcr.microsoft.com/dotnet/runtime-deps:11.0.0-alpine3.24 AS runtime
WORKDIR /app
COPY --from=build /app/publish/Inventory.Api ./

# Listen on all interfaces inside the container; Compose decides what the host can reach.
ENV Urls=http://0.0.0.0:8080
EXPOSE 8080

# The base image defines the unprivileged user "app" and sets APP_UID; never run the service as root.
USER $APP_UID
ENTRYPOINT ["./Inventory.Api"]
