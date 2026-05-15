![umbrelOS](https://github.com/user-attachments/assets/cabf8af7-51ce-45df-ad3a-a664cc91c610)

# TAO-Umbrel (Unofficial umbrelOS Docker Image)

This repository packages umbrelOS `1.7.3` into a Docker image that can be self-published to your own Docker Hub repository.

## Important notice

- This is an unofficial container image and is not supported by the Umbrel team.
- Base runtime starts from `tao9317/tao-umbrel:latest`, then upgrades umbreld/UI to `1.7.3`.
- Default **Docker Compose** matches the original **[WK188/TAO-Umbrel](https://github.com/WK188/TAO-Umbrel)** layout: data volume, Docker socket, published HTTP port (`80` by default). **Full host parity** (privileged, host network, `/dev`, udev, etc.) is **opt-in** via [`docker-compose.full-host.example.yml`](docker-compose.full-host.example.yml) if you need Umbrel **Files** on raw USB/block devices like bare-metal umbrelOS.

## Why this update matters

umbrelOS `1.7` introduces:

- Home screen shortcuts
- Built-in text editor in Files
- Advanced networking controls (hostname, DNS, static IP flow)
- Folder sharing improvements for external drives
- Files performance and UX improvements

umbrelOS `1.7.x` includes a fix for a storage error shown after restart on some devices. This image tracks upstream tag **`1.7.3`**; see [upstream `1.7.1`…`1.7.3` changes](https://github.com/getumbrel/umbrel/compare/1.7.1...1.7.3) for the full commit list.

## Host requirements

- **Minimal (default compose)** — Linux (or any host that can run this Linux image) with Docker Engine + Compose plugin; bind mount for **`/data`**; access to **`/var/run/docker.sock`** if you use Umbrel-managed apps. Published HTTP defaults to host port **`80`** (override with **`UMBREL_HTTP_PORT`**, e.g. **`8088`** on Unraid when port 80 is in use).
- **Full host parity (optional)** — Same as above, plus merge [`docker-compose.full-host.example.yml`](docker-compose.full-host.example.yml) for privileged mode, **`network_mode: host`**, and binds to **`/dev`**, **`/run/udev`**, **`/sys`**, **`/lib/modules`** when you need **Files** USB detection, formatting, and similar umbrelOS-on-hardware behavior.

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.full-host.example.yml docker compose up -d
```

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
./scripts/build-push.sh "${DOCKERHUB_USERNAME}/tao-umbrel" 1.7.3
```

If omitted, the script defaults to:

- Image: `shurikan117/tao-umbrel`
- Tag: `1.7.3` and `latest`

(Fork maintainers: replace with your Docker Hub namespace everywhere you see `shurikan117`.)

## Publish via GitHub Actions (no local disk)

If your laptop is low on free space, you can build and push entirely on GitHub-hosted runners (~14 GB ephemeral disk).

**Docker Hub tags:** Pushes to the **`dev`** branch only publish **`dev-<7-char-sha>`** (the suffix is the start of the git commit SHA in hex, for example `dev-1313073`). That is not the Umbrel version. To publish a **semver** tag such as **`1.7.3`** on Docker Hub (and optionally **`latest`**), either push a **`v*` git tag** (see step 4 below) or run **Actions → Docker build and push → Run workflow** and set **`version_tag`** to **`1.7.3`**.

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
git tag v1.7.3
git push origin v1.7.3
```

**Dev branch:** Pushes to `dev` that change the Docker image, helper scripts, or this workflow file trigger a build automatically. Those runs push **`shurikan117/tao-umbrel:dev-<7-char-sha>`** (when `DOCKER_IMAGE` is set) and do **not** move `:latest` (that stays for tag or manual runs that opt in).

The workflow builds `linux/amd64` only and caches layers via GitHub Actions cache to speed repeats.

### Image tag vs Umbrel source

- **Docker image tag** — What you set in Compose (`UMBREL_IMAGE`), in `workflow_dispatch` (`version_tag`), or when running `./scripts/build-push.sh … <tag>`. Example: `shurikan117/tao-umbrel:1.7.3`.
- **Upstream clone** — The `getumbrel/umbrel` git tag used during `docker build` comes from Dockerfile `ARG UMBREL_VERSION` (default `1.7.3`). CI passes `UMBREL_VERSION` as a build-arg so release tags and manual workflow runs match the pulled sources. **Dev branch** builds (`dev-<sha>` image tags) use the default from the first `ARG UMBREL_VERSION=` line in the Dockerfile so the clone stays a real semver tag, not the dev image name.

See also [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml).

## Run with `docker run` (minimal)

Same defaults as [`docker-compose.yml`](docker-compose.yml): data volume, Docker socket, published HTTP port, no privileged stack. Set **`UMBREL_IMAGE`**, **`UMBREL_DATA_HOST`**, and **`UMBREL_HTTP_PORT`** in your shell (or inline) as needed.

```bash
export UMBREL_IMAGE="${UMBREL_IMAGE:-shurikan117/tao-umbrel:1.7.3}"
export UMBREL_DATA_HOST="${UMBREL_DATA_HOST:-$PWD/umbrel}"
export UMBREL_HTTP_PORT="${UMBREL_HTTP_PORT:-80}"

docker run -d \
  --name umbrel \
  --pid host \
  --restart always \
  --stop-timeout 60 \
  -p "${UMBREL_HTTP_PORT}:80" \
  -v "${UMBREL_DATA_HOST}:/data" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "${UMBREL_IMAGE}"
```

**Kopia persistence** — Add another bind if the host directory exists, e.g. `-v "${UMBREL_DATA_HOST}/kopia:/kopia"`.

**Full host parity** (`--privileged`, `--network host`, `/dev`, udev, etc.) is easier to express with **Compose** and [`docker-compose.full-host.example.yml`](docker-compose.full-host.example.yml) than a long `docker run`; translate those YAML keys to extra `docker run` flags if you must run without Compose.

Open Umbrel at `http://<YOUR_HOST_IP>:${UMBREL_HTTP_PORT}` (default port **80**).

Stop / remove: `docker stop umbrel && docker rm umbrel`

### Unraid / `docker run` troubleshooting

- **`rugix-ctrl` ENOENT** — Umbreld calls Rugix tooling that exists only on real umbrelOS. Images **built from this repo** install a no-op **`rugix-ctrl`** in `/usr/local/bin` so startup can continue. **`docker pull`** the tag again after a rebuild, or use a fresh **`dev-<sha>`** image from CI.
- **`lstat '/data/umbrel-os'`** or **`scandir '/run/rugix/mounts/data/state'`** — The entrypoint and [`docker/migrate.sh`](docker/migrate.sh) create these stubs on each start. If you still see the errors, your local image is **older than those scripts**: `docker pull shurikan117/tao-umbrel:1.7.3` (or rebuild). As a one-off on the host: `mkdir -p /mnt/user/appdata/umbrel/umbrel-os`.
- **`LNXSYSTM:00` … `/sys` read-only** — Harmless on many Docker hosts. If other failures pile up, try adding **`--privileged`** (trades away minimal security posture).
- **`dataDirectory` shows a host path** — Umbreld may log the **source** of the `/data` bind mount; that is normal when you mount `/mnt/user/appdata/umbrel:/data`.
- **`[umbreld] Received SIGTERM` right after startup** — Usually **not** an Umbrel bug. Typical causes: **`docker run` without `-d`** (foreground: closing SSH, **Ctrl+C**, or Unraid UI ending the session sends SIGTERM); Unraid template/script stopping the job; or a duplicate **`--name`**. Fix: run with **`-d`** and **`--stop-timeout 60`**, then check **`docker ps`** (should show **Up**). Follow logs in another shell: **`docker logs -f umbrel`**.
- **`systemctl stop smbd` / `wsdd2` ENOENT** — Seen on **shutdown** when there is no systemd in the container. **Expected** in minimal Docker; safe to ignore unless SMB is misbehaving during normal use. Newer images include a no-op **`systemctl`** in **`/usr/local/bin`** to quiet these lines.

## Run with Docker Compose

Alternatively, use **Docker Compose**. The default [`docker-compose.yml`](docker-compose.yml) matches the original **TAO-Umbrel** style (bridge networking, published port, no privileged device stack):

```yaml
services:
  umbrel:
    image: ${UMBREL_IMAGE:-shurikan117/tao-umbrel:1.7.3}
    container_name: umbrel
    pid: host
    ports:
      - "${UMBREL_HTTP_PORT:-80}:80"
    volumes:
      - ${UMBREL_DATA_HOST:-./umbrel}:/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
    stop_grace_period: 1m
```

**Docker / Unraid (`/data` bind mount only)** — On bare-metal umbrelOS, `/data/umbrel-os` and Rugix state under `/run/rugix/...` already exist. In Docker you usually mount only app data at `/data`. The container creates stubs at startup: **`/run/rugix/mounts/data/state`** in [`docker/entrypoint.sh`](docker/entrypoint.sh), and **`${UMBREL_DATA_DIR:-/data}/umbrel-os`** in [`docker/migrate.sh`](docker/migrate.sh), so migrations (e.g. factory-reset backup cleanup) do not fail with `ENOENT` on those paths.

**Backups (Kopia)** — Published images dated before the Kopia change may lack the `kopia` binary inside the container. Until you pull a tag that includes it, validate backups using a **`dev-<sha>`** image from Actions or a **local build**.

**Persist `/kopia` and add extra binds** — Docker Compose merges `docker-compose.yml` with **`docker-compose.override.yml`** automatically (no extra `-f`):

```bash
cp docker-compose.override.example.yml docker-compose.override.yml
# Edit paths under `volumes`; optional: set `UMBREL_DATA_HOST` and `UMBREL_HTTP_PORT` in a project `.env` file (see [.env.local.example](.env.local.example))
docker compose up -d
```

`docker-compose.override.yml` is gitignored so host-specific paths stay local. Alternatively: `COMPOSE_FILE=docker-compose.yml:docker-compose.local.yml docker compose ...` merges files explicitly.

SELinux enforcing hosts sometimes need `:z` or `:Z` on bind mount definitions. NFS-heavy backup targets may need extra host packages (`nfs-common`); SMB is aligned with existing `cifs-utils` in the image. **Full-host compose** is better suited to attached USB / block-device workflows than the default minimal stack.

Start Umbrel:

```bash
docker compose up -d
```

Open Umbrel at:

```text
http://<YOUR_HOST_IP>:${UMBREL_HTTP_PORT:-80}
```

(If you did not set `UMBREL_HTTP_PORT`, use port **80**.)

## Migration from `tao9317/tao-umbrel:latest`

The persisted Umbrel state lives under **`UMBREL_DATA_HOST`** (default **`./umbrel`** on the host, mounted to **`/data`**).

1. Stop current container:

```bash
docker compose down
```

If you use **`docker run`** instead: `docker stop umbrel && docker rm umbrel`

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

With **`docker run`**: `docker pull "${UMBREL_IMAGE:-shurikan117/tao-umbrel:1.7.3}"` then run the **`docker run`** block from the **Run with `docker run` (minimal)** section above (stop/remove the old container first).

5. Watch startup logs:

```bash
docker logs -f umbrel
```

The migration helper warns about legacy markers and ensures an **`umbrel-os`** directory exists under the data mount; umbreld performs real data migrations itself.

## Full host parity (optional Files / disks)

The **default** compose does **not** mount **`/dev`**, **`/run/udev`**, **`/sys`**, or **`/lib/modules`**, and does **not** use **`privileged`** or **`network_mode: host`**. That matches the original **WK188/TAO-Umbrel** experience: simpler, fewer host integrations.

To approximate **bare-metal umbrelOS** for **Files** (USB disks in the sidebar, format actions, etc.), merge [`docker-compose.full-host.example.yml`](docker-compose.full-host.example.yml):

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.full-host.example.yml docker compose up -d
```

With **`network_mode: host`**, Umbrel listens on the host’s port **80** (and related ports) directly; the **`ports`** mapping from the base file is ignored at runtime. On **Unraid**, if the web UI already uses port **80**, use **minimal** compose with **`UMBREL_HTTP_PORT=8088`** instead, or move conflicting services off port 80.

Without full-host merges, **USB block-device flows in Files** may not work; **network mounts**, **SMB to NAS paths**, and **most apps** can still work with the minimal stack.

## Manual smoke checklist after upgrade

- Fresh install: onboarding succeeds.
- Existing `1.5.x` data: apps and data reappear after startup.
- **Full-host compose only** — Files: USB disk appears in sidebar; USB format action works.
- Files: built-in editor opens text files.
- Files: network mount to NAS works.
- **Full-host compose only** — Settings > Network: hostname/static-IP flow loads (host networking).
- Settings > File Sharing: SMB share from folder can be browsed from another machine (may still log `systemctl` errors on shutdown in Docker without systemd).
- Home: shortcut creation works.
- Backups: can target path-based destinations (e.g. bind-mounted host paths); external **USB-as-block-device** backups align with **full-host** compose.
- Restart test: no false storage error screen on reboot.

## Optional environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `UMBREL_IMAGE` | `shurikan117/tao-umbrel:1.7.3` | Image tag consumed by Compose |
| `UMBREL_DATA_HOST` | `./umbrel` | Host path mounted to `/data` in [`docker-compose.yml`](docker-compose.yml) |
| `UMBREL_HTTP_PORT` | `80` | Host port published to container port 80 (e.g. `8088` on Unraid) |
| `UMBREL_DATA_DIR` | `/data` | Data directory inside container |
| `COMPOSE_FILE` | _(unset)_ | Colon-separated Compose file list (e.g. add [`docker-compose.full-host.example.yml`](docker-compose.full-host.example.yml)) |
| `UMBRELD_RESTORE_SKIP_REBOOT` | _(unset)_ | Upstream umbreld: restore flow without reboot for debugging |
| `TZ` | `Etc/UTC` | Container timezone |

## License

UmbrelOS is licensed under `PolyForm Noncommercial 1.0.0`. This image remains subject to the same license terms.
