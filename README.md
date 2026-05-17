![umbrelOS](https://github.com/user-attachments/assets/cabf8af7-51ce-45df-ad3a-a664cc91c610)

# TAO-Umbrel (Unofficial umbrelOS Docker Image)

> **Important:** This is an unofficial image. It builds on [`tao9317/tao-umbrel:latest`](https://hub.docker.com/r/tao9317/tao-umbrel) (dockur-style wrapper) and replaces umbreld/UI with upstream **[umbrelOS 1.7.3](https://github.com/getumbrel/umbrel)**. Not supported by the Umbrel team. Official site: [umbrel.com](https://umbrel.com).

Same layout as [WK188/TAO-Umbrel](https://github.com/WK188/TAO-Umbrel): persist data, mount the Docker socket, publish HTTP port **80** by default.

Logs may show `Starting umbrelOS for Docker v1.5.0` from the base image; umbreld should report **v1.7.3**.

## Pull the image

```bash
docker pull shurikan117/tao-umbrel:1.7.3
```

## Run with Docker Compose (recommended)

Umbrel manages other containers, so mount the host Docker socket and use `pid: host`.

```yaml
services:
  umbrel:
    image: ${UMBREL_IMAGE:-shurikan117/tao-umbrel:1.7.3}
    container_name: umbrel
    hostname: umbrel
    pid: host
    ports:
      - "${UMBREL_HTTP_PORT:-80}:80"
    volumes:
      - ${UMBREL_DATA_HOST:-./umbrel}:/data
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      UMBREL_NETWORK_STORAGE_MODE: ${UMBREL_NETWORK_STORAGE_MODE:-auto}
      UMBREL_LOG_LEVEL: ${UMBREL_LOG_LEVEL:-normal}
      TZ: ${TZ:-Etc/UTC}
    restart: always
    stop_grace_period: 1m
```

```bash
docker compose up -d
```

## Run with `docker run`

```bash
export UMBREL_IMAGE="${UMBREL_IMAGE:-shurikan117/tao-umbrel:1.7.3}"
export UMBREL_DATA_HOST="${UMBREL_DATA_HOST:-./umbrel}"
export UMBREL_HTTP_PORT="${UMBREL_HTTP_PORT:-80}"

docker run -d \
  --name umbrel \
  --hostname umbrel \
  --pid host \
  --restart always \
  --stop-timeout 60 \
  -e UMBREL_NETWORK_STORAGE_MODE="${UMBREL_NETWORK_STORAGE_MODE:-auto}" \
  -e UMBREL_LOG_LEVEL="${UMBREL_LOG_LEVEL:-normal}" \
  -p "${UMBREL_HTTP_PORT}:80" \
  -v "${UMBREL_DATA_HOST}:/data" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "${UMBREL_IMAGE}"
```

## Access

After startup, open:

```text
http://<YOUR_HOST_IP>:${UMBREL_HTTP_PORT:-80}
```

## Upgrade from `tao9317/tao-umbrel:latest`

Keep the same host data directory; change the image and recreate:

```bash
export UMBREL_IMAGE=shurikan117/tao-umbrel:1.7.3
# UMBREL_DATA_HOST and UMBREL_HTTP_PORT unchanged from your existing setup

docker compose down
docker pull "${UMBREL_IMAGE}"
docker compose up -d
```

## Build and publish your own

```bash
cp .env.local.example .env.local
# edit DOCKERHUB_* and UMBREL_IMAGE as needed
set -a && source .env.local && set +a
./scripts/build-push.sh "${DOCKERHUB_USERNAME}/tao-umbrel" 1.7.3
```

GitHub Actions: see [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml). Push git tag `v1.7.3` or run the workflow with `version_tag` **1.7.3** to publish semver on Docker Hub.

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `UMBREL_IMAGE` | `shurikan117/tao-umbrel:1.7.3` | Image reference |
| `UMBREL_DATA_HOST` | `./umbrel` | Host path mounted to `/data` |
| `UMBREL_HTTP_PORT` | `80` | Host port mapped to container port 80 |
| `UMBREL_DATA_DIR` | `/data` | Data directory inside the container |
| `UMBREL_NETWORK_STORAGE_MODE` | `auto` | NAS/CIFS: `host` (mount on host first), `container` (umbreld mounts; you add `SYS_ADMIN`), or `auto` (host in Docker) |
| `UMBREL_LOG_LEVEL` | `normal` | umbreld logging: `silent`, `normal`, or `verbose` (`verbose` prints many `WS rpc` lines from the open dashboard) |
| `TZ` | `Etc/UTC` | Container timezone |

## Network storage / NAS backups

Umbrel mounts SMB shares for **Files → Network** and **Backups → NAS**. In Docker, in-container `mount -t cifs` usually needs **`CAP_SYS_ADMIN`** and still fails on many hosts (permission denied). Set behavior per deployment with **`UMBREL_NETWORK_STORAGE_MODE`**:

| Mode | Who mounts SMB | Typical use |
| --- | --- | --- |
| **`host`** | You mount on the host under `{UMBREL_DATA_HOST}/network/{host}/{share}` | Unraid, NAS, any shared `docker.sock` host |
| **`container`** | umbreld runs `mount -t cifs` | Dedicated box; add **`cap_add: [SYS_ADMIN]`** in *your* compose/run |
| **`auto`** | `host` if `/.dockerenv`, else `container` | Default when unset |

### Unraid / shared Docker (`host`)

1. Set in Compose or `docker run` (see [`.env.local.example`](.env.local.example)):

   ```bash
   export UMBREL_NETWORK_STORAGE_MODE=host
   ```

2. On the **host**, mount the share at the path Umbrel expects (example for share `main` on `192.168.74.117`):

   ```bash
   mkdir -p /mnt/user/appdata/umbrel/network/192.168.74.117/main
   mount -t cifs //192.168.74.117/main /mnt/user/appdata/umbrel/network/192.168.74.117/main \
     -o credentials=/boot/config/umbrel-nas.creds,uid=1000,gid=1000,iocharset=utf8,nofail
   ```

   Credentials file: `username=...` and `password=...` (mode `600`). Use an Unraid user that can access the share.

3. Verify: `mountpoint /mnt/user/appdata/umbrel/network/192.168.74.117/main`

4. In Umbrel UI, **Add share** (same host and credentials). If the host mount is already up, umbreld accepts it; if not, you get a clear error instead of a generic mount failure.

5. Persist the host mount via Unraid **User Scripts** (At Array Start) or `/boot/config/go`.

### In-container CIFS (`container`)

Not enabled in the default [`docker-compose.yml`](docker-compose.yml). Example override:

```yaml
services:
  umbrel:
    cap_add:
      - SYS_ADMIN
    environment:
      UMBREL_NETWORK_STORAGE_MODE: container
```

Pull a new image after updates; host-mount mode does not require extra container capabilities.

## If Files shows "The path is outside the allowed directory"

Built-in **Files → Home / Apps** can fail with this message when umbreld was started with the **host** path of the `/data` bind mount as `--data-directory` (dockur default) while path checks resolve under the container mount **`/data`**. Images from this repo ship a patched [`docker/entry.sh`](docker/entry.sh) that starts umbreld with **`UMBREL_DATA_DIR`** (default **`/data`**), which must match your volume target (`UMBREL_DATA_HOST` → `/data`).

After pulling a build that includes the fix, recreate the container, then verify:

```bash
# Should include --data-directory /data (not /mnt/user/... or other host source path)
docker exec umbrel tr '\0' ' ' </proc/1/cmdline; echo
```

Then open **Files → Home** and **Files → Apps** in the UI. Older images without the patched entry script need a **`docker pull`** and recreate; docs-only changes do not fix a running container.

## If Settings → Device info shows no CPU

RAM and storage come from `/proc/meminfo` and `df`; the CPU model uses **`lscpu`** (`util-linux`) with a **`/proc/cpuinfo`** fallback in patched images. Older images without `util-linux` may show a blank CPU line.

After pulling a current build:

```bash
docker exec umbrel lscpu | grep 'Model name'
docker exec umbrel sh -c 'grep -m1 "model name" /proc/cpuinfo'
```

Refresh **Settings → Device info**. Live CPU **usage** % is a separate code path (`top`); this section is only the CPU **model** string.

## If logs show `Received SIGTERM` and `ExitCode: 0`

That is a **graceful shutdown** (something sent SIGTERM)—often **not** a bad image.

- **`restart: always`** in Compose (and **`--restart always`** in `docker run`) matches this repo. **`unless-stopped`** does **not** restart the container after a manual **`docker stop`** or a UI **Stop** on some hosts; align with **`always`** if you want automatic restarts after crashes.
- Typical causes: Unraid **Stop** / **Apply** on the container, **`docker stop`**, foreground or console-attached runs, or closing a session that was tied to the container. Avoid **`-it`** for the long-running umbrel instance; use **`-d`**.
- Confirm both mounts are present: **`UMBREL_DATA_HOST` → `/data`** and **`/var/run/docker.sock` → `/var/run/docker.sock`**.

**Upstream behavior on shared Docker (Unraid, etc.):** umbreld 1.7.3 `cleanDockerState()` runs `docker ps -aq` then `docker stop` on **every** container on the socket. With a host `docker.sock`, that can stop **this** Umbrel container right after **“Cleaning up old containers…”**. Images built from this repo patch umbreld to skip that global cleanup in container/shared-socket mode (`UMBREL_DISABLE_GLOBAL_DOCKER_CLEANUP=1` and `/.dockerenv`). Rebuild and **`docker pull`** a new tag after changing the image.

See who stopped the container (run while starting in another shell):

```bash
docker events --filter container=umbrel
```

If SIGTERM persists with no manual stop on an **old** image without the patch, try the same **`docker run`** line **without** `--pid host` once (some hosts behave oddly with host PID mode).

Warnings like **`version` is obsolete** in upstream `legacy-compat/docker-compose.yml`, or **`Starting umbrelOS for Docker v1.5.0`** from the base image, are usually harmless noise if umbreld reports **v1.7.3**.

## If apps won't install (Unraid / shared Docker)

App installs need a **current image built from this repo** (`shurikan117/tao-umbrel:1.7.3` or a **`dev-<sha>`** tag from CI on `dev`). Stock **`tao9317/tao-umbrel:latest`** alone does not include the umbreld patches or patched [`docker/entry.sh`](docker/entry.sh).

**Older CI tags (e.g. `dev-e8e796a`) are missing fixes** added after that commit: `--data-directory /data`, skip global Docker cleanup on shared `docker.sock`, and bundled umbreld patches. Pull a newer **`dev-<sha>`** after pushing to `dev`, or rebuild locally.

Endless **`WS rpc backups.backupProgress`** / **`widget.data`** lines with **`logLevel: verbose`** are **dashboard polling**, not install errors. Use **`UMBREL_LOG_LEVEL=normal`** (default) to reduce noise.

### Verify the running container

```bash
docker inspect umbrel --format '{{.Config.Image}}'

# Must include --data-directory /data (not /mnt/user/appdata/umbrel or other host source path)
docker exec umbrel tr '\0' ' ' </proc/1/cmdline; echo

docker logs umbrel 2>&1 | grep -E 'Skipping global Docker cleanup|Cleaning up old containers|dataDirectory:|Installing app|Failed to install|app environment'

docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'umbrel|auth|tor_proxy'

docker exec umbrel sh -c 'touch /data/.w && rm /data/.w && ls -la /data/app-stores /data/app-data 2>/dev/null | head'
```

**Pass criteria:**

- `--data-directory /data` in the cmdline
- Startup log contains **`Skipping global Docker cleanup`** (not **`Cleaning up old containers...`** followed by exit)
- **`auth`** and **`tor_proxy`** containers exist and are **Up**
- `/data` is writable; **`app-stores/`** populated

While clicking **Install** in the UI:

```bash
docker logs -f umbrel 2>&1 | grep -iE 'Installing app|Failed to install|pull|compose|permission|EACCES|denied'
```

### Recreate on Unraid with a current image

```bash
docker rm -f umbrel 2>/dev/null
docker pull shurikan117/tao-umbrel:dev-<7-char-sha>   # or :1.7.3 after Hub publish

docker run -d \
  --name umbrel \
  --hostname umbrel \
  --pid host \
  --restart always \
  --stop-timeout 60 \
  -p 8088:80 \
  -v /mnt/user/appdata/umbrel:/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  shurikan117/tao-umbrel:dev-<7-char-sha>
```

Re-run the verification commands above, then try installing one small app. A new **`<app>_…`** container should appear in **`docker ps`**.

### If `/data` permission errors appear

Umbreld and app containers expect uid **1000** for tor and many app volumes. On the host:

```bash
chown -R 1000:1000 /mnt/user/appdata/umbrel
chmod -R u+rwX /mnt/user/appdata/umbrel
```

Avoid read-only or **`root_squash`** CIFS for the Umbrel appdata share if installs fail with **`EACCES`**.

## License

UmbrelOS is licensed under PolyForm Noncommercial 1.0.0. This image remains subject to the same license terms.
