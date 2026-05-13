## Learned User Preferences

- Treat disk space as a hard constraint on this machine: run disk preflight before heavy Docker builds, stop builds when free space is tight, and avoid actions that risk filling the disk.
- When local Docker builds are impractical due to space, rely on GitHub Actions to build and push images rather than forcing long local build/push loops.
- Keep Docker Hub and image settings in `.env.local` (gitignored), patterned on `.env.local.example`; source that file before running `./scripts/build-push.sh`.
- Derive Docker Hub image names, GitHub Actions `DOCKER_IMAGE`, and related settings from `.env.local` plus repository metadata when those are available, rather than prompting for values already present on disk.
- Avoid merging to `main` just to unblock CI when work lives on feature branches such as `dev`; prefer workflow triggers or branch selection that match where the YAML actually lives.

## Learned Workspace Facts

- Container upgrade path builds upstream `getumbrel/umbrel` at umbrel tag `1.7.3` and layers onto `tao9317/tao-umbrel:latest`; base layout uses `/opt/umbreld`, so image detection/install paths account for `/opt/umbreld` as well as older probe locations.
- `scripts/build-push.sh` wraps build/push with an isolated Docker CLI config without credential helpers (plus `cli-plugins` link for Buildx), optional non-interactive `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` login, and a `MIN_FREE_GIB` disk preflight.
- `docker-compose.yml` targets Linux hosts: privileged runtime, host networking, and bind mounts including `/dev`, `/run/udev`, `/sys`, and `/lib/modules` for Umbrel Files and external drive flows.
- Active workflow `.github/workflows/docker-publish.yml` builds/pushes `linux/amd64`; pushes to branch `dev` that touch Dockerfile, `docker/`, `scripts/`, or this workflow emit an image tag `dev-<short-sha>` and do not promote `:latest` from those runs; semver releases use pushed tags matching `v*`.
- Resolved Docker image names are lowercased in CI (Docker rejects uppercase repository namespaces); overrides use repo variable `DOCKER_IMAGE` when GitHub owner does not match the Docker Hub namespace.
- Published image for this fork is **`shurikan117/tao-umbrel`**; set GitHub Actions variable `DOCKER_IMAGE` to that value when the GitHub repository owner differs from the Docker Hub namespace.
- Dockerfile `builder` stage pins `node:22.13.0-bookworm` to match the upstream umbrelOS Node line used when building umbreld/UI.
- GitHub Actions `docker-publish.yml` passes `UMBREL_VERSION` as a Docker build-arg for every build: semver / manual runs use the workflow image tag; `dev-*` runs set it from the first `ARG UMBREL_VERSION=` in the `Dockerfile` so the clone stays a real upstream tag, not the `dev-<sha>` image name.
- Umbrel backup flows expect **Kopia** plus **`fuse3`** and **`bindfs`** in the image; persist Kopia cache/config by merging `docker-compose.override.example.yml` (mount `${UMBREL_DATA:-./umbrel}/kopia` to `/kopia`); local `docker-compose.override.yml` and project `.env` are gitignored for host-specific paths.
- Workflow sets `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` and uses current major pins for checkout, Docker Buildx, login, and build-push Actions to align with Actions Node deprecation timelines.
