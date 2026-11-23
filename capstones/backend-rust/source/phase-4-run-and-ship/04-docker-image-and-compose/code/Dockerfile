# syntax=docker/dockerfile:1

# ---- Stage 1: build ---------------------------------------------------------
FROM rust:1.100.0-slim-trixie AS build
WORKDIR /app

# Layer A: the dependencies only. A stub program lets Cargo compile every crate once.
# Docker reuses this layer as long as Cargo.toml and Cargo.lock do not change.
COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
    && touch src/lib.rs \
    && echo "fn main() {}" > src/main.rs \
    && cargo build --release --locked \
    && rm -rf src

# Layer B: our own code. Only this layer is rebuilt after an edit in src/.
# COPY keeps the old file times of your disk, which look older than the stub build above, so Cargo would
# call the stub "up to date" and ship it. `touch` gives the real files a new time and forces the rebuild.
COPY src ./src
RUN touch src/lib.rs src/main.rs \
    && cargo build --release --locked

# ---- Stage 2: run -----------------------------------------------------------
# distroless "cc" has glibc and nothing else: no shell, no package manager. "nonroot" is user 65532.
FROM gcr.io/distroless/cc-debian13:nonroot
COPY --from=build /app/target/release/tasks-api /usr/local/bin/tasks-api
USER nonroot:nonroot
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 CMD ["/usr/local/bin/tasks-api", "healthcheck"]
ENTRYPOINT ["/usr/local/bin/tasks-api"]
