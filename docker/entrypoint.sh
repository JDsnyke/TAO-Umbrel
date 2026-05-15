#!/usr/bin/env bash
set -euo pipefail

data_dir="${UMBREL_DATA_DIR:-/data}"

mkdir -p /run/dbus /run/rugix/mounts/data/state "${data_dir}/umbrel-os"

if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
  dbus-daemon --system --fork || true
fi

if [ "$#" -eq 0 ]; then
  set -- /usr/bin/tini -s /run/entry.sh
fi

exec "$@"
