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
    pid: host
    ports:
      - "${UMBREL_HTTP_PORT:-80}:80"
    volumes:
      - ${UMBREL_DATA_HOST:-./umbrel}:/data
      - /var/run/docker.sock:/var/run/docker.sock
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
  --pid host \
  --restart always \
  --stop-timeout 60 \
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
| `TZ` | `Etc/UTC` | Container timezone |

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

## License

UmbrelOS is licensed under PolyForm Noncommercial 1.0.0. This image remains subject to the same license terms.
