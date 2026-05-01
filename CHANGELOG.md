# Changelog

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
