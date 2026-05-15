#!/usr/bin/env bash
set -euo pipefail

data_dir="${UMBREL_DATA_DIR:-/data}"

echo "Running TAO-Umbrel migration guard for umbreld ${UMBREL_VERSION:-unknown}"

if [ ! -d "$data_dir" ]; then
  echo "Data directory '$data_dir' does not exist yet, skipping migration checks."
  exit 0
fi

# Stub umbrelOS data layout so umbreld migrations do not ENOENT on bind-mounted Docker data only.
mkdir -p "${data_dir}/umbrel-os"

# We never mutate user data here; umbreld performs schema migrations itself.
legacy_markers=(
  "$data_dir/umbrel.pid"
  "$data_dir/.umbrel-legacy-layout"
)

for marker in "${legacy_markers[@]}"; do
  if [ -e "$marker" ]; then
    echo "WARN: Detected legacy marker '$marker'."
    echo "WARN: Ensure this instance was fully stopped before upgrading."
  fi
done

echo "Migration guard completed."
