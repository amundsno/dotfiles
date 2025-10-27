#!/bin/bash
set -euo pipefail

# Link the Docker Buildx CLI tool for building instead of the legacy builder
# Docs: https://docs.docker.com/build/concepts/overview/#install-buildx

mkdir -p ~/.docker/cli-plugins
ln -sfn "$(which docker-buildx)" ~/.docker/cli-plugins/docker-buildx
if buildx_version=$(docker buildx version 2>/dev/null); then
    echo "✅ Docker Buildx linked successfully (linked version: $buildx_version)"
fi