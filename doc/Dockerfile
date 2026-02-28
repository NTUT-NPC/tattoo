FROM debian:trixie-slim@sha256:1d3c811171a08a5adaa4a163fbafd96b61b87aa871bbc7aa15431ac275d3d430 AS builder

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

FROM caddy:2-alpine@sha256:3b2a0196e0687279c14c27adff9fc6b44acfa318dbb97eaebe385bdf99e5364c

# Copy generated documentation
COPY --from=builder /app/doc/api /usr/share/caddy

EXPOSE 80
