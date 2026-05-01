#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-${UMBREL_IMAGE:-your-dockerhub-user/tao-umbrel}}"
TAG="${2:-1.7.1}"
MIN_FREE_GIB="${MIN_FREE_GIB:-18}"

available_kb="$(df -Pk . | awk 'NR==2 {print $4}')"
required_kb="$((MIN_FREE_GIB * 1024 * 1024))"
if [ "${available_kb:-0}" -lt "$required_kb" ]; then
  echo "ERROR: Not enough free disk space for Docker build."
  echo "Need at least ${MIN_FREE_GIB}GiB free. Available: $((available_kb / 1024 / 1024))GiB."
  exit 1
fi

tmp_docker_config="$(mktemp -d)"
trap 'rm -rf "$tmp_docker_config"' EXIT
cat >"${tmp_docker_config}/config.json" <<'JSON'
{
  "auths": {}
}
JSON
if [ -d "$HOME/.docker/cli-plugins" ]; then
  ln -s "$HOME/.docker/cli-plugins" "${tmp_docker_config}/cli-plugins"
fi

if [ -n "${DOCKERHUB_USERNAME:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
  printf '%s' "$DOCKERHUB_TOKEN" | docker --config "$tmp_docker_config" login -u "$DOCKERHUB_USERNAME" --password-stdin
fi

docker --config "$tmp_docker_config" buildx build \
  --platform linux/amd64 \
  --tag "${IMAGE}:${TAG}" \
  --tag "${IMAGE}:latest" \
  --push .
