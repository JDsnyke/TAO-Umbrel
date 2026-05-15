## Learned User Preferences

- Treat disk space as a hard constraint on this machine: run disk preflight before heavy Docker builds, stop builds when free space is tight, and avoid actions that risk filling the disk.
- When local Docker builds are impractical due to space, rely on GitHub Actions to build and push images rather than forcing long local build/push loops.
- Keep Docker Hub and image settings in `.env.local` (gitignored), patterned on `.env.local.example`; source that file before running `./scripts/build-push.sh`.
- Derive Docker Hub image names, GitHub Actions `DOCKER_IMAGE`, and related settings from `.env.local` plus repository metadata when those are available, rather than prompting for values already present on disk.
- Avoid merging to `main` just to unblock CI when work lives on feature branches such as `dev`; prefer workflow triggers or branch selection that match where the YAML actually lives.

## Learned Workspace Facts

- Image builds on `tao9317/tao-umbrel:latest`, replaces umbreld/UI with `getumbrel/umbrel` tag **1.7.3**; minimal Docker patches in `docker/` (entrypoint stubs, rugix-ctrl, systemctl, Kopia).
- Default [`docker-compose.yml`](docker-compose.yml) matches WK188: `UMBREL_DATA_HOST` → `/data`, `/var/run/docker.sock`, `UMBREL_HTTP_PORT` → 80, `pid: host`, `restart: always`.
- Published image for this fork is **`shurikan117/tao-umbrel`**; set GitHub Actions variable `DOCKER_IMAGE` when the GitHub repository owner differs from the Docker Hub namespace.
- `scripts/build-push.sh` wraps build/push with isolated Docker CLI config and `MIN_FREE_GIB` disk preflight.
- Workflow `.github/workflows/docker-publish.yml` pushes **`dev`** on branch pushes (docker paths only); semver **`1.7.3`** from `v*` tags or manual dispatch.
- Running containers are not updated by git/docs alone—hosts must `docker pull` and recreate with both `/data` and `docker.sock` mounts.
