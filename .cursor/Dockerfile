FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    sudo \
    curl \
    unzip \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

ARG GODOT_VERSION=4.6.3
RUN mkdir -p /opt/godot \
    && curl -fsSL -o /tmp/godot.zip \
        "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && unzip -q /tmp/godot.zip -d /tmp/godot-extract \
    && mv "/tmp/godot-extract/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /opt/godot/godot \
    && chmod +x /opt/godot/godot \
    && ln -sf /opt/godot/godot /usr/local/bin/godot \
    && ln -sf /opt/godot/godot /usr/local/bin/godot4 \
    && rm -rf /tmp/godot.zip /tmp/godot-extract

ENV GODOT_DISABLE_LEAK_CHECKS=1
