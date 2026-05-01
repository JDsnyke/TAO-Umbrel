#!/usr/bin/env bash
set -euo pipefail

if [ -n "${DOCKER_CONFIG:-}" ]; then
  docker --config "$DOCKER_CONFIG" compose pull
  docker --config "$DOCKER_CONFIG" compose up -d
else
  docker compose pull
  docker compose up -d
fi
