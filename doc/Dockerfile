FROM debian:trixie-slim@sha256:cedb1ef40439206b673ee8b33a46a03a0c9fa90bf3732f54704f99cb061d2c5a AS builder

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

FROM caddy:2-alpine@sha256:834468128c7696cec0ceea6172f7d692daf645ae51983ca76e39da54a97c570d

# Copy generated documentation
COPY --from=builder /app/doc/api /usr/share/caddy

EXPOSE 80
