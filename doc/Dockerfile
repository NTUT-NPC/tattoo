FROM debian:trixie-slim@sha256:f6e2cfac5cf956ea044b4bd75e6397b4372ad88fe00908045e9a0d21712ae3ba AS builder

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

FROM caddy:2-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d

# Copy generated documentation
COPY --from=builder /app/doc/api /usr/share/caddy

EXPOSE 80
