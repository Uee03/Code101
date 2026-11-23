# syntax=docker/dockerfile:1

# Stage 1: build with the SDK image (compiler, NuGet, about 1 GB). Nothing from this stage ships except the published output.
FROM mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24 AS build
WORKDIR /src

# Restore first, on its own layer: it only re-runs when the project file or the SDK pin changes.
COPY global.json ./
COPY src/TasksApi/TasksApi.csproj src/TasksApi/
RUN dotnet restore src/TasksApi/TasksApi.csproj

COPY src/TasksApi/ src/TasksApi/
RUN dotnet publish src/TasksApi/TasksApi.csproj -c Release --no-restore -o /app/publish /p:UseAppHost=false

# Stage 2: run on the small ASP.NET runtime image (no SDK, no compiler, no shell tools beyond Alpine's busybox).
FROM mcr.microsoft.com/dotnet/aspnet:11.0.0-alpine3.24 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./

# Listen on all interfaces inside the container; Compose decides what the host can reach (127.0.0.1:8000 only).
# The key is Urls, the same key appsettings.json uses: a setting in appsettings.json beats ASPNETCORE_URLS.
ENV Urls=http://0.0.0.0:8000 \
    DOTNET_EnableDiagnostics=0
EXPOSE 8000

# The base image defines the unprivileged user "app" and sets APP_UID; never run the service as root.
USER $APP_UID
ENTRYPOINT ["dotnet", "TasksApi.dll"]
