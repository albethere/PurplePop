Here’s a drop-in “project brief” you can paste into a new Codex / ChatGPT conversation so it immediately understands what PurplePop is, how the repo is structured, and what still needs doing.

You can also drop this into `docs/PROJECT_OVERVIEW.md` in the repo if you want it versioned.

---

## PurplePop – Project Overview for Assistant

### 1. High-level Goal

**PurplePop** is a custom, reproducible, Pop!_OS-based live image intended to be flashed to USB and used for:

* Purple-team work (offense/defense lab tasks)
* DFIR / troubleshooting on random hardware
* Having a consistent, familiar toolset regardless of host machine

Key design points:

* **Base OS:** Pop!_OS 22.04 LTS (64-bit)
* **Usage mode:** Stateless live system (no persistence required). When it gets stale, rebuild ISO and reflash.
* **Primary WM/DE:**

  * Sway (Wayland tiling, primary session)
  * XFCE (classic X11 desktop, fallback session)
* **Terminal:** Waveterm as the primary terminal, with Alacritty as fallback.
* **Tooling:** Curated purple-team / DFIR / networking tools installed via apt, pipx, etc., plus quick helper scripts like `dfir-quick.sh` and `net-quick.sh` shipped in the image.

The repo is meant to be the **single source of truth** for:

* Package manifests
* Dotfiles (shell, WM, terminal configs)
* ISO build scripts
* CI workflow to build the ISO in GitHub Actions

---

### 2. Core Behavior & Constraints

* All customizations are applied onto a **stock Pop!_OS 22.04 ISO**; metadata (filename, URL, checksum) lives in `image/base-popos.yaml`.
* Build artifacts live under `.build/` (base ISO, extracted ISO, chroot) and the final ISO is written to `out/`.
* Dotfiles in `dotfiles/` are treated as canonical; `/etc/skel` inside the chroot is populated from them via `scripts/apply-overlays.sh`.
* Quick helper utilities (`dfir-quick.sh`, `net-quick.sh`) ship from `iso/overlay/usr/local/bin` and are made executable in the chroot.
* LightDM is the expected display manager, with Sway as the default session and XFCE available as fallback.

---

### 3. Branch & CI Details

* **Default branch:** `main`
* **CI:** GitHub Actions workflow at `.github/workflows/build-purplepop.yml`

  * Runs on Ubuntu runner
  * Installs build deps (`squashfs-tools`, `xorriso`, `bsdtar`, `p7zip-full`, `curl`)
  * Marks build scripts and filesystem hooks executable
  * Executes `scripts/build-iso.sh`
  * Uploads `out/*.iso` as an artifact named `purplepop-iso`

The old `ci/github-actions.yml` directory is redundant and either already removed or should be removed.

---

### 4. Repository Structure & Roles

High-level tree with purpose of each major directory:

```text
PurplePop/
├── .github/
│   ├── workflows/
│   │   └── build-purplepop.yml      # CI workflow to build the ISO
│   └── instructions/                # Additional repo instructions (e.g., Snyk rules)
│
├── config/                         # System overlays (sudoers, MOTD, netplan/hosts stubs, users.yml)
├── dfir-playbooks/                 # DFIR Playbooks (Linux/Mac/Windows artifact guides, cheatsheets)
├── docker/                         # docker-compose stacks (BloodHound, CyberChef, Neo4j, Portainer)
|
├── dotfiles/
│   ├── zsh/                        # .zshrc, aliases, prompt
│   ├── sway/                       # Sway config + keybindings cheat sheet
│   ├── waybar/                     # Waybar modules + theme
│   ├── xfce/                       # XFCE panel/desktop XML + terminal defaults
│   ├── waveterm/                   # Waveterm profiles
│   ├── i3/                         # Legacy i3 config
│   └── git/                        # .gitconfig for live user
│
├── image/
│   ├── base-popos.yaml             # Pop!_OS metadata (version, filename, URL, checksum)
│   └── filesystem-hooks/
│       ├── 10-install-packages.sh  # (stub) placeholder hook
│       ├── 20-configure-users.sh   # Creates live user, sets LightDM default session
│       ├── 30-desktop-setup.sh     # (stub) placeholder hook
│       └── 40-cleanup.sh           # (stub) placeholder hook
│
├── iso/
│   └── overlay/
│       ├── etc/skel/.config/.zshrc # Placeholder; /etc/skel is populated from dotfiles during build
│       └── usr/local/bin/          # Helper scripts bundled into the image
│           ├── dfir-quick.sh
│           └── net-quick.sh
│
│
├── manifests/
│   ├── apt-packages.base.txt       # Core utilities
│   ├── apt-packages.gui.txt        # Sway, XFCE, GUI tooling
│   ├── apt-packages.dfir.txt       # DFIR tooling
│   ├── apt-packages.netsec.txt     # Netsec tooling
│   ├── brew-packages.txt           # Homebrew packages (not yet wired into builds)
│   ├── flatpak-apps.txt            # Flatpak apps (currently empty)
│   └── pipx-tools.txt              # Python CLIs to install via pipx
│
├── scripts/
│   ├── build-iso.sh                # Entry point orchestrating the full build
│   ├── download-base.sh            # Downloads and verifies the Pop!_OS ISO from metadata
│   ├── create-chroot.sh            # Extracts ISO + unsquashes filesystem into .build/chroot
│   ├── install-tooling.sh          # Installs apt packages + optional pipx tools inside chroot
│   ├── apply-overlays.sh           # Applies iso/overlay + syncs dotfiles into /etc/skel; chmod /usr/local/bin
│   ├── finalize-image.sh           # Rebuilds squashfs and crafts the final ISO via xorriso
│   └── helpers/                    # Helpers (detect-ubuntu-version, log stubs)
│
├── LICENSE
├── README.md
└── docs/                           # Project docs (project overview, build readiness notes)
```

---

### 5. Build Pipeline (Scripts & Order)

The intended build flow on a Linux host is:

1. **`scripts/build-iso.sh`**
   Main orchestrator; creates `.build/`, then calls each stage in order.

2. **`scripts/download-base.sh`**
   * Reads filename/URL/checksum from `image/base-popos.yaml` (currently parsed as JSON; comments in the file will break it).
   * Downloads the ISO into `.build/base/` if missing or checksum fails.
   * Verifies SHA-256 before proceeding.

3. **`scripts/create-chroot.sh`**
   * Extracts the ISO into `.build/iso-root/` using `bsdtar`.
   * Unsquashes `casper/filesystem.squashfs` into `.build/chroot/` using `unsquashfs`.
   * (Binding `/dev`, `/proc`, `/sys`, `/run` is not yet implemented; apt operations later may need that.)

4. **`scripts/install-tooling.sh`**
   * Copies `manifests/*.txt` into `/manifests` inside the chroot.
   * Runs `apt-get update` then installs packages from each `apt-packages*.txt`.
   * Installs `pipx` and tools from `pipx-tools.txt` if present.
   * Cleans apt cache.

5. **`scripts/apply-overlays.sh`**
   Responsibilities:

   * `rsync` everything from `iso/overlay/` into the chroot (including helper scripts).
   * Populate `/etc/skel` inside chroot from `dotfiles/`:

     * `dotfiles/zsh` → `/etc/skel/.zshrc` and `/etc/skel/.config/zsh/*`
     * `dotfiles/sway` → `/etc/skel/.config/sway/`
     * `dotfiles/waybar` → `/etc/skel/.config/waybar/`
     * `dotfiles/xfce` → `/etc/skel/.config/xfce4/...`
     * `dotfiles/waveterm` → `/etc/skel/.config/waveterm/`
     * `dotfiles/git/.gitconfig` → `/etc/skel/.gitconfig`
   * Ensure `/usr/local/bin` in chroot is `a+rx` so helper scripts are executable.

   **Important convention:**
   `dotfiles/` is the *canonical* source of truth; `/etc/skel` contents are derived from it, not edited directly in the overlay.

6. **`image/filesystem-hooks/20-configure-users.sh`**
   * Creates the live user (default `purplepop`) with `/usr/bin/zsh` shell and sudo/adm/cdrom/plugdev groups.
   * Clears the password, fixes ownership of the home directory, and sets LightDM as the display manager.
   * Writes a LightDM config making Sway the default session (XFCE remains selectable) and enables `lightdm.service` inside the chroot.

7. **`scripts/finalize-image.sh`**
   * Unmounts bind mounts if present.
   * Rebuilds `casper/filesystem.squashfs` with `mksquashfs` and updates `casper/filesystem.size`.
   * Crafts a hybrid BIOS/UEFI ISO in `out/PurplePop-YYYYMMDD.iso` using `xorriso`, reusing Pop!_OS boot artifacts.

8. **Flashing**
   * Out of scope for this repo/CI.
   * User will use BalenaEtcher, Rufus, or similar with the ISO artifact.

---

### 6. Current Status & Known Gaps



**Already in good shape:**

* Pop!_OS metadata (`image/base-popos.yaml`) now populated with the real ISO URL and checksum; `download-base.sh` verifies it.
* Core build pipeline scripts exist and are wired together via `build-iso.sh`.
* Dotfiles for Sway, Waybar, XFCE, zsh, Waveterm, git are synced into `/etc/skel` during overlay.
* Helper scripts (`dfir-quick.sh`, `net-quick.sh`) are bundled into `/usr/local/bin` via the overlay and made executable.
* Live user setup and LightDM default session are handled by `20-configure-users.sh` during the build.
* GitHub Actions workflow builds the ISO artifact end-to-end and uploads it.

**Needs attention / completion:**

1. **Metadata parsing mismatch*

   * `download-base.sh` uses `json.load` on `image/base-popos.yaml`, which currently contains YAML-style comments; parsing will fail unless the file stays JSON-clean or the script switches to proper YAML parsing.

2. **Chroot mount/setup**

   * `create-chroot.sh` does not yet bind `/dev`, `/proc`, `/sys`, `/run`, or set up DNS inside the chroot. `install-tooling.sh` may need those mounts for more complex installs.

3. **Filesystem hooks**
   * Hooks `10-install-packages.sh`, `30-desktop-setup.sh`, and `40-cleanup.sh` are stubs. Decide whether to wire them into the pipeline or remove them.

4. **Homebrew/Flatpak manifests**
   * `brew-packages.txt` and `flatpak-apps.txt` exist but are not consumed anywhere yet.

5. **Docs and usage**
   * Build/usage instructions beyond this overview are minimal; `docs/build-readiness.md` is empty.

---

### 7. How a New Assistant Should Work With This

When you (assistant) are asked to continue work on PurplePop, you should:

1. **Respect the existing conventions:**

   * `dotfiles/` is source of truth; `/etc/skel` is derived.
   * `manifests/*.txt` drive what gets installed.
   * The build pipeline order is: download → extract → chroot → install → overlay/dotfiles → configure user/sessions → finalize.

2. **When adding features:**

   * Prefer to add/modify files in `dotfiles/`, `manifests/`, `iso/overlay/`, `image/filesystem-hooks/`, and `scripts/`, not random new locations.
   * Keep the repo tree coherent; if you add new scripts or tooling, update docs / comments accordingly.

3. **When updating the build pipeline:**

   * Make sure `scripts/build-iso.sh` remains the **one true entrypoint** for building.
   * If you split new logic into extra scripts, plug them into `build-iso.sh` in a clear, documented order.

4. **When asked for TODOs / next tasks:**

   * Suggest focused improvements like:

     * Fixing metadata parsing (YAML vs JSON) and hardening checksum verification
     * Adding chroot bind mounts / DNS for package installs
     * Wiring up Homebrew/Flatpak manifests
     * Adding documentation in `docs/` (BUILD, USAGE, CONTRIBUTING)

---

Tasks to prioritize:

* Harden metadata parsing and ISO download verification logic
* Add chroot mount/teardown helpers so installs behave like a real system
* Decide on and implement remaining filesystem hooks (or remove them)
* Wire up optional package sources (Homebrew/Flatpak) and document how to use them
* Flesh out build/usage docs and add debugging aids for first test builds
