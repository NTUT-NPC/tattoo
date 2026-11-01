FROM debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS builder

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV PATH="/mise/shims:$PATH"

RUN curl https://mise.run | sh

# Set working directory
WORKDIR /app

# Copy mise configuration and install Flutter
COPY mise.toml .
RUN --mount=type=cache,target=/mise/cache \
    mise trust && \
    mise install flutter

# Resolve app dependencies and generate documentation
COPY . .
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter --disable-analytics && \
    flutter pub get --enforce-lockfile && \
    dart doc

FROM caddy:2-alpine@sha256:e70b164da81ef698b3ad19af799ea6086ce6d9e48ed4079eb9fe26f6fbf14ee5

# Copy generated documentation
COPY --from=builder /app/doc/api /usr/share/caddy

EXPOSE 80
