![umbrelOS](https://github.com/user-attachments/assets/cabf8af7-51ce-45df-ad3a-a664cc91c610)

# TAO-Umbrel (Unofficial umbrelOS Docker Image)

This repository packages umbrelOS `1.7.1` into a Docker image that can be self-published to your own Docker Hub repository.

## Important notice

- This is an unofficial container image and is not supported by the Umbrel team.
- Base runtime starts from `tao9317/tao-umbrel:latest`, then upgrades umbreld/UI to `1.7.1`.
- Linux host is required for full device passthrough support.

## Why this update matters

umbrelOS `1.7` introduces:

- Home screen shortcuts
- Built-in text editor in Files
- Advanced networking controls (hostname, DNS, static IP flow)
- Folder sharing improvements for external drives
- Files performance and UX improvements

umbrelOS `1.7.1` additionally fixes a storage error issue shown after restart on some devices.

## Host requirements

- Linux Docker host (bare metal or VM)
- Docker Engine with Compose plugin
- Access to host devices for drive detection:
  - `/dev`
  - `/run/udev`
  - `/sys`
  - `/lib/modules` (read-only)
- Privileged container runtime (required for format/mount flows in Files)

## Build and publish your own image

1. Create local env file:

```bash
cp .env.local.example .env.local
```

2. Load env vars:

```bash
set -a
source .env.local
set +a
```

3. Build and push:

```bash
./scripts/build-push.sh "${DOCKERHUB_USERNAME}/tao-umbrel" 1.7.1
```

If omitted, the script defaults to:

- Image: `shurikan117/tao-umbrel`
- Tag: `1.7.1` and `latest`

(Fork maintainers: replace with your Docker Hub namespace everywhere you see `shurikan117`.)

## Publish via GitHub Actions (no local disk)

If your laptop is low on free space, you can build and push entirely on GitHub-hosted runners (~14 GB ephemeral disk).

1. Push this repository to GitHub.

2. In the repo settings, add Actions secrets (**Settings → Secrets and variables → Actions**):
   - **`DOCKERHUB_USERNAME`**: must equal the Docker Hub account that can **push** to your image (for this fork: **`shurikan117`**).
   - **`DOCKERHUB_TOKEN`**: a Docker Hub **access token** with **Read, Write & Delete** (or equivalent push) scopes—not a read-only PAT.

   If `DOCKERHUB_USERNAME` and the token belong to different accounts, or the PAT is read-only, pushes fail with errors like **`insufficient_scope`** or **`push access denied`**.

3. Repository variable (**Settings → Secrets and variables → Actions → Variables**):
   - **`DOCKER_IMAGE`**: full Docker Hub name **`shurikan117/tao-umbrel`** (required when your GitHub owner slug differs from your Docker Hub namespace).

   Tag-triggered and dev-branch CI runs read `DOCKER_IMAGE` when set; otherwise they fall back to **`{github-owner}/tao-umbrel`** (GitHub slug, lowercased), which is wrong for forks where the Hub repo lives under another user.

4. Run either:
   - **Actions → Docker build and push → Run workflow** (optional overrides for image tag and `:latest`). If the workflow file only exists on `dev`, open **Use workflow from** and choose **`dev`** so GitHub loads that YAML.
   - Or push a semver tag:

```bash
git tag v1.7.1
git push origin v1.7.1
```

**Dev branch:** Pushes to `dev` that change the Docker image, helper scripts, or this workflow file trigger a build automatically. Those runs push **`shurikan117/tao-umbrel:dev-<7-char-sha>`** (when `DOCKER_IMAGE` is set) and do **not** move `:latest` (that stays for tag or manual runs that opt in).

The workflow builds `linux/amd64` only and caches layers via GitHub Actions cache to speed repeats.

See also [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml).

## Run with Docker Compose

The included `docker-compose.yml` defaults to:

```yaml
image: ${UMBREL_IMAGE:-shurikan117/tao-umbrel:1.7.1}
```

**Backups (Kopia)** — Published images dated before the Kopia change may lack the `kopia` binary inside the container. Until you pull a tag that includes it, validate backups using a **`dev-<sha>`** image from Actions or a **local build**.

**Persist `/kopia` and add extra binds** — Docker Compose merges `docker-compose.yml` with **`docker-compose.override.yml`** automatically (no extra `-f`):

```bash
cp docker-compose.override.example.yml docker-compose.override.yml
# Edit paths under `volumes`; optional: set `UMBREL_DATA` in a project `.env` file (see [.env.local.example](.env.local.example))
docker compose up -d
```

`docker-compose.override.yml` is gitignored so host-specific paths stay local. Alternatively: `COMPOSE_FILE=docker-compose.yml:docker-compose.local.yml docker compose ...` merges files explicitly.

SELinux enforcing hosts sometimes need `:z` or `:Z` on bind mount definitions. NFS-heavy backup targets may need extra host packages (`nfs-common`); SMB is aligned with existing `cifs-utils`. Attached USB/external-drive backups assume a **Linux** Docker host—not Docker Desktop on macOS.

Start Umbrel:

```bash
docker compose up -d
```

Open Umbrel at:

```text
http://<YOUR_LINUX_HOST_IP>
```

## Migration from `tao9317/tao-umbrel:latest`

The persisted Umbrel state lives in `./umbrel` (mounted to `/data`).

1. Stop current container:

```bash
docker compose down
```

2. Backup current data directory:

```bash
cp -a umbrel "umbrel.bak.$(date +%F)"
```

3. Point compose image to your new image tag using either:
- `UMBREL_IMAGE` environment variable, or
- direct edit in `docker-compose.yml`

4. Pull and start:

```bash
docker compose pull
docker compose up -d
```

5. Watch startup logs:

```bash
docker logs -f umbrel
```

The migration helper only warns about legacy markers; umbreld performs real data migrations itself.

## Device detection and Files behavior

To allow Files to detect and manage local disks, this setup enables:

- `privileged: true`
- `network_mode: host`
- host mounts for `/dev`, `/run/udev`, `/sys`

Without these, external device detection, formatting, and network share workflows may fail.

## Manual smoke checklist after upgrade

- Fresh install: onboarding succeeds.
- Existing `1.5.x` data: apps and data reappear after startup.
- Files: USB disk appears in sidebar.
- Files: USB format action works.
- Files: built-in editor opens text files.
- Files: network mount to NAS works.
- Settings > Network: hostname/static-IP flow loads.
- Settings > File Sharing: SMB share from folder can be browsed from another machine.
- Home: shortcut creation works.
- Backups: can target external drive and run at least one backup.
- Restart test: no false storage error screen on reboot.

## Optional environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `UMBREL_IMAGE` | `shurikan117/tao-umbrel:1.7.1` | Image tag consumed by Compose |
| `UMBREL_DATA` | `./umbrel` | Host path prefix for `…/kopia:/kopia` in [docker-compose.override.example.yml](docker-compose.override.example.yml) |
| `UMBREL_DATA_DIR` | `/data` | Data directory inside container |
| `COMPOSE_FILE` | _(unset)_ | Colon-separated list of Compose files if not using `docker-compose.override.yml` |
| `UMBRELD_RESTORE_SKIP_REBOOT` | _(unset)_ | Upstream umbreld: restore flow without reboot for debugging |
| `TZ` | `Etc/UTC` | Container timezone |

## License

UmbrelOS is licensed under `PolyForm Noncommercial 1.0.0`. This image remains subject to the same license terms.
