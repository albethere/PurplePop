# Build readiness checklist (first ISO pass)

This audit captures the gaps to close before attempting the first full PurplePop ISO build.

## Immediate blockers
- `scripts/apply-overlays.sh` now exits cleanly; it previously had a stray `endif` that prevented the script from running, which would have halted the pipeline before `/etc/skel` population.

## Still-missing pieces to address
- **Checksum enforcement**: `scripts/download-base.sh` downloads the Pop!_OS ISO without validating the SHA256. We should read the value from `image/base-popos.yaml` and fail the build if it does not match.
- **Pop!_OS metadata usage**: `image/base-popos.yaml` now records version, architecture, filename, URL, and checksum, but the scripts still hardcode these values. Wiring the YAML into the download step will keep the metadata in sync.
- **User/session setup**: There is no step that creates the live user, sets its shell to zsh, or configures LightDM sessions (Sway/XFCE). Add a hook/script and call it from `build-iso.sh` after overlays.
- **Bootloader flags**: `scripts/finalize-image.sh` calls `xorriso` with generic flags; we may need Pop!_OS-specific options to preserve bootability on UEFI/BIOS hardware.
- **Chroot cleanup**: `create-chroot.sh` binds host filesystems but never unmounts them if a later step fails; consider a trap/cleanup helper.
- **Unused placeholders**: `scripts/helpers/log.sh`, `scripts/helpers/detect-ubuntu-version.sh`, `scripts/flash-usb.sh`, and `config/users.yml` are empty stubs. Either implement them or remove them to avoid confusion.
- **Overlay drift**: `iso/overlay` still contains an `/etc/skel` snapshot. Because dotfiles are meant to be the source of truth, we should prune stale skel files or ensure the overlay is limited to non-dotfile content.