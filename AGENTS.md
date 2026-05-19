## Learned User Preferences

- Treat disk space as a hard constraint on this machine: run disk preflight before heavy Docker builds, stop builds when free space is tight, and avoid actions that risk filling the disk.
- When local Docker builds are impractical due to space, rely on GitHub Actions to build and push images rather than forcing long local build/push loops.
- Keep Docker Hub and image settings in `.env.local` (gitignored), patterned on `.env.local.example`; source that file before running `./scripts/build-push.sh`.
- Derive Docker Hub image names, GitHub Actions `DOCKER_IMAGE`, and related settings from `.env.local` plus repository metadata when those are available, rather than prompting for values already present on disk.
- Avoid merging to `main` just to unblock CI when work lives on feature branches such as `dev`; prefer workflow triggers or branch selection that match where the YAML actually lives.
- Build and maintain TAO-Umbrel as WK188-minimal: `tao9317/tao-umbrel:latest` plus umbreld/UI **1.7.3** and only the Docker compatibility patches required to run in a container; do not treat docs-only changes as host/runtime fixes.
- Set `UMBREL_DATA_HOST`, `UMBREL_HTTP_PORT`, and `UMBREL_IMAGE` per host; keep canonical repo defaults and docs on WK188-style values (`./umbrel`, port 80)—avoid hardcoding Unraid-specific paths or ports in the main upgrade/runbook.
- Prefer pinned semver Docker Hub tags (e.g. `1.7.3`) for stable production upgrades rather than relying only on moving `dev` or `dev-<sha>` tags.
- Prefer **`docker run`** for the minimal WK188-style stack when convenient; keep Docker Compose in the repo for overrides and documented examples.
- On **Unraid** and similar NAS Docker hosts, do not add `/dev`, udev, `/sys`, or privileged device binds to the canonical minimal stack unless USB block-device **Files** parity is explicitly required—match original WK188/TAO-Umbrel scope.

## Learned Workspace Facts

- Image builds on `tao9317/tao-umbrel:latest`, replaces umbreld/UI with `getumbrel/umbrel` tag **1.7.3**; `docker/` holds entrypoint (rugix state path, `umbrel-os` stub, merged migrate logic), `rugix-ctrl` and `systemctl` stubs, and Kopia.
- Default [`docker-compose.yml`](docker-compose.yml) matches WK188: `UMBREL_DATA_HOST` → `/data`, `/var/run/docker.sock`, `UMBREL_HTTP_PORT` → 80, `pid: host`, `restart: always`.
- After cb0b610 reset, repo ships WK188-minimal compose only; removed `docker-compose.full-host.example.yml` and `docker-compose.override.example.yml`.
- Published image for this fork is **`shurikan117/tao-umbrel`**; set GitHub Actions variable `DOCKER_IMAGE` when the GitHub repository owner differs from the Docker Hub namespace.
- `scripts/build-push.sh` wraps build/push with isolated Docker CLI config and `MIN_FREE_GIB` disk preflight.
- Workflow `.github/workflows/docker-publish.yml` pushes **`dev`** and **`dev-<7-char-sha>`** on `dev` branch pushes (docker paths only); semver **`1.7.3`** from `v*` tags or manual dispatch.
- Running containers are not updated by git/docs alone—hosts must `docker pull` and recreate with both `/data` and `docker.sock` mounts.
- umbreld 1.7.3 `cleanDockerState()` runs `docker ps -aq` then `docker stop` on every container on the socket; with a host `docker.sock` that can SIGTERM this Umbrel container—`docker/patches/umbreld-shared-docker-cleanup.patch` skips global cleanup when `UMBREL_DISABLE_GLOBAL_DOCKER_CLEANUP=1` or `/.dockerenv`.
- NAS/CIFS for backups and Files uses **`UMBREL_NETWORK_STORAGE_MODE`** per host (`host` | `container` | `auto` via Compose/`docker run`); Unraid-style Docker should use **`host`** and mount SMB on the host under `{UMBREL_DATA_HOST}/network/...` — see [`docker/patches/umbreld-network-storage-host-mount.patch`](docker/patches/umbreld-network-storage-host-mount.patch). Do not add `SYS_ADMIN` to canonical compose by default.
- Settings **Device info** CPU model needs `lscpu` (`util-linux` in the image) or [`docker/patches/umbreld-device-cpu-fallback.patch`](docker/patches/umbreld-device-cpu-fallback.patch) reading `/proc/cpuinfo`; RAM/storage do not use `lscpu`.
- Files **Home/Apps** error "path is outside the allowed directory" (`[escapes-base]`) when dockur **`/run/entry.sh`** passes the **host** bind-mount source as **`--data-directory`** while umbreld 1.7.3 resolves under **`/data`** via symlink; fix by shipping **`docker/entry.sh`** as **`/run/entry.sh`** with **`--data-directory ${UMBREL_DATA_DIR:-/data}`** (image rebuild required).
- Docker app-install/runtime: do not `docker network rm umbrel_main_network` on start ([`docker/entry.sh`](docker/entry.sh)) — disconnects **auth** / **tor_proxy**; PID 1 is **tini** (use `pgrep umbreld` or `dataDirectory:` logs for `/data`, not `/proc/1/cmdline`); many **Skipping global Docker cleanup** lines = **restart loop**, not patch failure.
