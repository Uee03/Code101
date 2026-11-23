# syntax=docker/dockerfile:1

# Stage 1: build with the SDK image (compiler, NuGet; large). Only the published output leaves this stage.
FROM mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24 AS build
WORKDIR /src

# Restore first, on its own layer: it only re-runs when the SDK pin or the project file changes.
COPY global.json ./
COPY NotesApi/NotesApi.csproj NotesApi/
RUN dotnet restore NotesApi/NotesApi.csproj

COPY NotesApi/ NotesApi/
RUN dotnet publish NotesApi/NotesApi.csproj -c Release --no-restore -o /app/publish /p:UseAppHost=false

# Stage 2: run on the small ASP.NET runtime image (no SDK, no compiler).
FROM mcr.microsoft.com/dotnet/aspnet:11.0.0-alpine3.24 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./

# Listen on port 8080 inside the container; Compose decides what the host can reach.
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

# The base image defines the unprivileged user "app" and sets APP_UID; never run the service as root.
USER $APP_UID
ENTRYPOINT ["dotnet", "NotesApi.dll"]
