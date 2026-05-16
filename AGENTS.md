## Learned User Preferences

- Treat disk space as a hard constraint on this machine: run disk preflight before heavy Docker builds, stop builds when free space is tight, and avoid actions that risk filling the disk.
- When local Docker builds are impractical due to space, rely on GitHub Actions to build and push images rather than forcing long local build/push loops.
- Keep Docker Hub and image settings in `.env.local` (gitignored), patterned on `.env.local.example`; source that file before running `./scripts/build-push.sh`.
- Derive Docker Hub image names, GitHub Actions `DOCKER_IMAGE`, and related settings from `.env.local` plus repository metadata when those are available, rather than prompting for values already present on disk.
- Avoid merging to `main` just to unblock CI when work lives on feature branches such as `dev`; prefer workflow triggers or branch selection that match where the YAML actually lives.
- Build and maintain TAO-Umbrel as WK188-minimal: `tao9317/tao-umbrel:latest` plus umbreld/UI **1.7.3** and only the Docker compatibility patches required to run in a container; do not treat docs-only changes as host/runtime fixes.
- Set `UMBREL_DATA_HOST`, `UMBREL_HTTP_PORT`, and `UMBREL_IMAGE` per host; keep canonical repo defaults and docs on WK188-style values (`./umbrel`, port 80)—avoid hardcoding Unraid-specific paths or ports in the main upgrade/runbook.
- Prefer pinned semver Docker Hub tags (e.g. `1.7.3`) for stable production upgrades rather than relying only on moving `dev` or `dev-<sha>` tags.

## Learned Workspace Facts

- Image builds on `tao9317/tao-umbrel:latest`, replaces umbreld/UI with `getumbrel/umbrel` tag **1.7.3**; `docker/` holds entrypoint (rugix state path, `umbrel-os` stub, merged migrate logic), `rugix-ctrl` and `systemctl` stubs, and Kopia.
- Default [`docker-compose.yml`](docker-compose.yml) matches WK188: `UMBREL_DATA_HOST` → `/data`, `/var/run/docker.sock`, `UMBREL_HTTP_PORT` → 80, `pid: host`, `restart: always`.
- After cb0b610 reset, repo ships WK188-minimal compose only; removed `docker-compose.full-host.example.yml` and `docker-compose.override.example.yml`.
- Published image for this fork is **`shurikan117/tao-umbrel`**; set GitHub Actions variable `DOCKER_IMAGE` when the GitHub repository owner differs from the Docker Hub namespace.
- `scripts/build-push.sh` wraps build/push with isolated Docker CLI config and `MIN_FREE_GIB` disk preflight.
- Workflow `.github/workflows/docker-publish.yml` pushes **`dev`** on branch pushes (docker paths only); semver **`1.7.3`** from `v*` tags or manual dispatch.
- Running containers are not updated by git/docs alone—hosts must `docker pull` and recreate with both `/data` and `docker.sock` mounts.
- umbreld 1.7.3 `cleanDockerState()` runs `docker ps -aq` then `docker stop` on every container on the socket; with a host `docker.sock` that can SIGTERM this Umbrel container—`docker/patches/umbreld-shared-docker-cleanup.patch` skips global cleanup when `UMBREL_DISABLE_GLOBAL_DOCKER_CLEANUP=1` or `/.dockerenv`.
- Upstream umbreld 1.7.3 `cleanDockerState()` runs `docker ps -aq` then stops/removes **all** daemon containers; with a host `docker.sock` that can SIGTERM the Umbrel container (logs: **Cleaning up old containers…**). This fork patches umbreld via [`docker/patches/umbreld-shared-docker-cleanup.patch`](docker/patches/umbreld-shared-docker-cleanup.patch) and sets `UMBREL_DISABLE_GLOBAL_DOCKER_CLEANUP=1` in the image.
