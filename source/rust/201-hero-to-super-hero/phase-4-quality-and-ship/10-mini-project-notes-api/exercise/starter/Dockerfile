FROM rust:1.100.0-bookworm AS dependencies
WORKDIR /app
COPY Cargo.toml ./
COPY build-stub ./src
RUN cargo build --release

FROM dependencies AS build
COPY src ./src
RUN touch src/main.rs src/lib.rs && cargo build --release --locked

FROM debian:bookworm-20261104-slim AS runtime
WORKDIR /app
COPY --from=build /app/target/release/notes_api /app/notes_api
ENV BIND_ADDR=0.0.0.0:3110
USER 10001:10001
EXPOSE 3110
STOPSIGNAL SIGINT
ENTRYPOINT ["/app/notes_api"]
