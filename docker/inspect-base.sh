#!/usr/bin/env bash
set -euo pipefail

declare -a probe_dirs=(
  "/opt/umbreld"
  "/usr/lib/umbreld"
  "/opt/umbrel/umbreld"
  "/home/umbrel/umbrel/packages/umbreld"
)

has_umbreld=0
for dir in "${probe_dirs[@]}"; do
  if [ -d "$dir" ]; then
    has_umbreld=1
    echo "Found legacy umbreld path: $dir"
  fi
done

if [ "$has_umbreld" -eq 0 ]; then
  echo "ERROR: Could not detect legacy umbreld install path in base image."
  echo "Expected one of: ${probe_dirs[*]}"
  exit 1
fi

if [ ! -S /var/run/docker.sock ]; then
  echo "WARN: /var/run/docker.sock not available during build context."
fi
