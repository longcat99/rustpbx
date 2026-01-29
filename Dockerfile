FROM rust:bookworm AS rust-builder
RUN apt-get update && apt-get install -y gcc-aarch64-linux-gnu libasound2-dev libopus-dev cmake
RUN rustup target add aarch64-unknown-linux-gnu
RUN mkdir -p ~/.cargo && \
    echo '[target.aarch64-unknown-linux-gnu]' >> ~/.cargo/config.toml && \
    echo 'linker = "aarch64-linux-gnu-gcc"' >> ~/.cargo/config.toml
RUN mkdir /build
ADD . /build/
WORKDIR /build
RUN --mount=type=cache,target=/build/.cargo/registry \
    --mount=type=cache,target=/build/target/aarch64-unknown-linux-gnu/release/incremental\
    --mount=type=cache,target=/build/target/aarch64-unknown-linux-gnu/release/build\
    cargo build --release --target aarch64-unknown-linux-gnu --bin rustpbx --bin sipflow

FROM debian:bookworm
LABEL maintainer="shenjindi@miuda.ai"
RUN --mount=type=cache,target=/var/apt apt-get update && apt-get install -y ca-certificates tzdata libopus0
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

WORKDIR /app
COPY --from=rust-builder /build/static /app/static
COPY --from=rust-builder /build/src/addons/acme/static /app/static/acme
COPY --from=rust-builder /build/src/addons/transcript/static /app/static/transcript
COPY --from=rust-builder /build/src/addons/queue/static /app/static/queue

COPY --from=rust-builder /build/target/aarch64-unknown-linux-gnu/release/rustpbx /app/rustpbx
COPY --from=rust-builder /build/target/aarch64-unknown-linux-gnu/release/sipflow /app/sipflow
COPY --from=rust-builder /build/templates /app/templates
COPY --from=rust-builder /build/src/addons/acme/templates /app/templates/acme
COPY --from=rust-builder /build/src/addons/archive/templates /app/templates/archive
COPY --from=rust-builder /build/src/addons/queue/templates /app/templates/queue
COPY --from=rust-builder /build/src/addons/transcript/templates /app/templates/transcript
COPY --from=rust-builder /build/config/sounds /app/sounds

ENTRYPOINT ["/app/rustpbx"]
