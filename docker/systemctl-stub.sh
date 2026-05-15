#!/usr/bin/env sh
# Real umbrelOS uses systemd. In Docker, umbreld still calls `systemctl stop smbd` / wsdd2 on shutdown.
# No-op: there is no systemd in this image; exiting 0 avoids ENOENT noise in logs.
exit 0
