FROM debian:trixie-slim@sha256:77ba0164de17b88dd0bf6cdc8f65569e6e5fa6cd256562998b62553134a00ef0 AS builder

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

# Resolve app dependencies
COPY pubspec.* ./
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter --disable-analytics && \
    flutter pub get --enforce-lockfile

# Copy app source code
COPY . .

# Generate documentation
RUN --mount=type=cache,target=/root/.pub-cache \
    dart doc

FROM caddy:2-alpine@sha256:d266901f6e0c9d74528463654b7e872e6af8f6bbe23ca13576a1fb601202f8da

# Copy generated documentation
COPY --from=builder /app/doc/api /usr/share/caddy

EXPOSE 80
