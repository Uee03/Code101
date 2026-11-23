FROM golang:1.27.4-alpine3.24 AS build
WORKDIR /src

# Copy the module file first: this layer is cached until go.mod changes.
COPY go.mod ./
RUN go mod download

COPY . .
# The image is only built if the tests pass.
RUN go vet ./... && go test ./...
# CGO_ENABLED=0 gives a static binary with no C library. -trimpath removes local file paths from the binary,
# -s -w remove the symbol table and debug information.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/notes .

# The runtime image has no shell and no package manager, and runs as user 65532 (nonroot).
FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /out/notes /app/notes
USER nonroot:nonroot
EXPOSE 8080
ENV APP_ADDR=0.0.0.0:8080 APP_LOG_FORMAT=json
ENTRYPOINT ["/app/notes"]
