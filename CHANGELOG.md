# Changelog

## 1.7.3-container.0

### Compose
- Default [`docker-compose.yml`](docker-compose.yml) is **minimal** (original [WK188/TAO-Umbrel](https://github.com/WK188/TAO-Umbrel) style): `UMBREL_DATA_HOST` → `/data`, Docker socket, `UMBREL_HTTP_PORT` → host port 80; no privileged / host network / device binds by default.
- Added [`docker-compose.full-host.example.yml`](docker-compose.full-host.example.yml) for optional **full umbrelOS parity** (merge via `COMPOSE_FILE` when Files USB/block workflows are needed).
- [`docker-compose.override.example.yml`](docker-compose.override.example.yml) uses **`UMBREL_DATA_HOST`** for the `/kopia` bind (aligned with main compose).

### Base update
- Upgraded Umbrel payload from upstream tag `1.7.1` to **`1.7.3`** ([compare](https://github.com/getumbrel/umbrel/compare/1.7.1...1.7.3)).
- Default Docker Hub example / Compose image tag is **`shurikan117/tao-umbrel:1.7.3`** (namespace unchanged).

### Container/runtime changes
- Pinned builder image to **`node:22.13.0-bookworm`** to match upstream umbrelOS Node line.
- GitHub Actions passes **`UMBREL_VERSION`** as a Docker build-arg for tag and manual runs so image labels match the cloned Umbrel revision; dev-branch builds use the Dockerfile default.
- No-op **`rugix-ctrl`** at **`/usr/local/bin/rugix-ctrl`** so umbreld does not fail with **`spawn rugix-ctrl ENOENT`** on plain Docker (real Rugix exists only on umbrelOS).

## 1.7.1-container.0

### Base update
- Upgraded Umbrel payload from `1.5.0` lineage to `umbrelOS 1.7.1` components.
- Kept compatibility with existing host-bound `/data` volume for in-place migration.

### Container/runtime changes
- Added multi-stage Docker build to pull upstream `getumbrel/umbrel` at tag `1.7.1`.
- Added runtime dependencies for disk detection and network shares:
  - `udev`, `udisks2`, `dbus`
  - `samba`, `smbclient`, `cifs-utils`
  - `usbutils`, `e2fsprogs`, `ntfs-3g`, `exfatprogs`
- Added entrypoint bootstrap to initialize dbus/udev and run a no-mutation migration guard.

### Compose changes
- Added Linux device passthrough mounts (`/dev`, `/run/udev`, `/sys`, `/lib/modules`).
- Enabled privileged mode and `SYS_ADMIN` capability for external-drive workflows.
- Switched to `network_mode: host` for better LAN/share behavior.
- Added `UMBREL_IMAGE` override to simplify custom Docker Hub tags.

### Regression validation checklist
- Fresh onboarding with empty data directory.
- Migration from existing `1.5.x` data directory.
- Files app USB detection, format action, network mounts, and built-in editor.
- Settings networking controls and folder sharing behavior.
- Restart validation for the `1.7.1` storage error fix.
