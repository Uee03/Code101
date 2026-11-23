# Stage 1: build a static binary. This stage is thrown away; only the file it produces is copied on.
FROM golang:1.27.4-alpine3.24 AS build
WORKDIR /src

# Copy the module files first: this layer is cached until go.mod or go.sum changes.
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# CGO_ENABLED=0 gives a static binary with no C library. -trimpath removes local file paths from the binary,
# -s -w remove the symbol table and debug information.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api

# Stage 2: the runtime image. "static" holds only CA certificates, time zone data and a passwd entry,
# with no shell and no package manager, and "nonroot" runs as user 65532.
FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /out/api /app/api
USER nonroot:nonroot
EXPOSE 8000
ENV LISTEN_ADDR=0.0.0.0:8000 LOG_FORMAT=json
ENTRYPOINT ["/app/api"]
