#!/usr/bin/env bash
set -euo pipefail

mkdir -p /run/dbus
if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
  dbus-daemon --system --fork || true
fi

if command -v udevadm >/dev/null 2>&1; then
  udevadm trigger || true
  udevadm settle || true
fi

/usr/local/bin/migrate.sh || true

if [ "$#" -eq 0 ]; then
  set -- /usr/bin/tini -s /run/entry.sh
fi

exec "$@"
