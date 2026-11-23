FROM rust:1.100.0-slim-trixie AS build
WORKDIR /app
ENV RUSTFLAGS="--remap-path-prefix=/app=/src --remap-path-prefix=/usr/local/cargo=/cargo"
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release --locked

# distroless "cc" has the C runtime libraries and nothing else: no shell, no package manager.
FROM gcr.io/distroless/cc-debian13:nonroot
COPY --from=build /app/target/release/token_check /app/token_check
USER nonroot:nonroot
ENTRYPOINT ["/app/token_check"]
