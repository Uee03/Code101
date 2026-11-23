# syntax=docker/dockerfile:1
FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/hello .

FROM scratch
COPY --from=build /out/hello /hello
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/hello"]
