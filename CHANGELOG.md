# Changelog

## 1.7.3-container.1

### Reset (WK188-minimal)

- Image: `tao9317/tao-umbrel:latest` base with umbreld/UI from upstream **1.7.3** only.
- Docker patches only: `rugix-ctrl` and `systemctl` no-ops, thin entrypoint (`/run/rugix/...`, `umbrel-os` stub on `/data`), Kopia + fuse3 for backups.
- Compose matches [WK188/TAO-Umbrel](https://github.com/WK188/TAO-Umbrel): data volume, Docker socket, port 80, `pid: host`, `restart: always`.
- Removed optional full-host and override compose examples from the repo surface.

## 1.7.3-container.0

Initial 1.7.3 payload on TAO-Umbrel base (see git history for earlier compose experiments).
