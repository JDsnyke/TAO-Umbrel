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

- Image: `your-dockerhub-user/tao-umbrel`
- Tag: `1.7.1` and `latest`

## Publish via GitHub Actions (no local disk)

If your laptop is low on free space, you can build and push entirely on GitHub-hosted runners (~14 GB ephemeral disk).

1. Push this repository to GitHub.

2. In the repo settings, add Actions secrets (**Settings → Secrets and variables → Actions**):
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN` (recommended: Docker Hub Access Token scoped to Docker Hub CLI)

3. Optional repository variable (**Settings → Secrets and variables → Actions → Variables**):
   - `DOCKER_IMAGE`: full Docker Hub name, for example `myuser/tao-umbrel`.

   Tag-triggered runs (`push` of git tags matching `v*`) use `DOCKER_IMAGE` when set; otherwise they default to **`{github-owner}/tao-umbrel`** (your GitHub username or org slug from the fork URL, not necessarily your Docker Hub username). Set `DOCKER_IMAGE` unless those match.

4. Run either:
   - **Actions → Docker build and push → Run workflow** (optional overrides for image tag and `:latest`). If the workflow file only exists on `dev`, open **Use workflow from** and choose **`dev`** so GitHub loads that YAML.
   - Or push a semver tag:

```bash
git tag v1.7.1
git push origin v1.7.1
```

**Dev branch:** Pushes to `dev` that change the Docker image, helper scripts, or this workflow file trigger a build automatically. Those runs push **`your-image:dev-<7-char-sha>`** and do **not** move `:latest` (that stays for tag or manual runs that opt in).

The workflow builds `linux/amd64` only and caches layers via GitHub Actions cache to speed repeats.

See also [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml).

## Run with Docker Compose

The included `docker-compose.yml` defaults to:

```yaml
image: ${UMBREL_IMAGE:-your-dockerhub-user/tao-umbrel:1.7.1}
```

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
| `UMBREL_IMAGE` | `your-dockerhub-user/tao-umbrel:1.7.1` | Image tag consumed by Compose |
| `UMBREL_DATA_DIR` | `/data` | Data directory inside container |
| `TZ` | `Etc/UTC` | Container timezone |

## License

UmbrelOS is licensed under `PolyForm Noncommercial 1.0.0`. This image remains subject to the same license terms.
