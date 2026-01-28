FROM debian:trixie-slim@sha256:77ba0164de17b88dd0bf6cdc8f65569e6e5fa6cd256562998b62553134a00ef0 AS builder

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl jq git xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Get Flutter version from .fvmrc and download Flutter SDK
COPY .fvmrc .
RUN FLUTTER_VERSION=$(jq -r .flutter .fvmrc) && \
    mkdir -p /flutter && \
    curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | \
    tar -xJC /flutter --strip-components=1

RUN git config --global --add safe.directory /flutter

# Add Flutter to PATH
ENV PATH="/flutter/bin:${PATH}"

# Resolve app dependencies
COPY ../pubspec.* ./
RUN flutter pub get

# Copy app source code
COPY . .

# Generate documentation
RUN dart doc

FROM caddy:2-alpine@sha256:d266901f6e0c9d74528463654b7e872e6af8f6bbe23ca13576a1fb601202f8da

# Copy generated documentation
COPY --from=builder /app/doc/api /usr/share/caddy

EXPOSE 80
