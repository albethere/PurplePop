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
* **Tooling:** Curated purple-team / DFIR / networking tools installed via apt, pipx, etc.

The repo is meant to be the **single source of truth** for:

* Package manifests
* Dotfiles (shell, WM, terminal configs)
* ISO build scripts
* CI workflow to build the ISO in GitHub Actions

---

### 2. Core Behavior & Constraints

* All customizations are applied onto a **stock Pop!_OS 22.04 ISO**.
* The build pipeline:

  1. Downloads the Pop!_OS ISO
  2. Extracts it, unsquashes the root filesystem
  3. Chroots into the rootfs
  4. Installs tools based on `manifests/*.txt`
  5. Applies overlays & dotfiles into `/etc/skel` so the live user inherits them
  6. Rebuilds `filesystem.squashfs`
  7. Rebuilds the ISO
* No need for a “flash USB” script in CI; the resulting ISO will be flashed with tools like **balenaEtcher** or **Rufus**.

---

### 3. Branch & CI Details

* **Default branch:** `main`
* **CI:** GitHub Actions workflow at `.github/workflows/build-purplepop.yml`

  * Runs on Ubuntu runner
  * Installs build deps (`squashfs-tools`, `xorriso`, `bsdtar`, `curl`, etc.)
  * Marks scripts executable
  * Runs `scripts/build-iso.sh`
  * Uploads `out/*.iso` as an artifact named `purplepop-iso`

The old `ci/github-actions.yml` directory is redundant and either already removed or should be removed.

---

### 4. Repository Structure & Roles

High-level tree with purpose of each major directory:

```text
PurplePop/
├── .github/
│   └── workflows/
│       └── build-purplepop.yml      # CI workflow to build the ISO
│
├── config/
│   ├── motd/10-purple-pop           # MOTD/login banner (optional)
│   ├── network/hosts                # /etc/hosts overlay (if used)
│   ├── network/netplan.yaml         # Netplan config overlay (if used)
│   ├── sudoers.d/liveuser           # Sudo rules for live user
│   └── users.yml                    # Intended structure for default live users
│
├── dfir-playbooks/                  # DFIR Playbooks
│   ├── linux-artifacts.md           # Linux artifact collection
│   ├── macos-artifacts.md           # MacOS artifact collection
│   ├── quickcheck-cheatsheet.md   
│   └── windows-artifacts.md         # Windows artifact collection
|
├── docker/                          # docker-compose stacks (BloodHound, CyberChef, etc.)
│   ├── bloodhound
│   ├── cyberchef
│   ├── neo4j
│   └── portainer
|
├── dotfiles/
│   ├── zsh/
│   │   ├── .zshrc                   # oh-my-zsh should be installed
│   │   ├── aliases.zsh
│   │   └── prompt.zsh
│   ├── sway/
│   │   ├── config                   # Sway config (Super key, bindings, Waveterm, etc.)
│   │   └── keybindings.md           # Human-readable cheatsheet
│   ├── waybar/
│   │   ├── config                   # Waybar modules
│   │   └── style.css                # Waybar theme
│   ├── xfce/
│   │   ├── xfce4-panel.xml          # XFCE panel layout
│   │   ├── xfce4-desktop.xml        # XFCE background + icons behavior
│   │   └── terminalrc               # XFCE Terminal defaults
│   ├── waveterm/
│   │   ├── waveterm.json            # Global Waveterm config
│   │   └── profiles/default.json    # Default Waveterm profile (zsh, colors)
│   ├── i3/
│   │   ├── config
│   │   └── i3status.conf
│   └── git/
│       └── .gitconfig               # Default Git config for live user
│
├── image/
│   ├── base-popos.yaml              # Metadata: Pop!_OS version, ISO filename, URL, checksum
│   └── filesystem-hooks/            # Hooks intended to run inside chroot (currently mostly stubs)
│       ├── 10-install-packages.sh
│       ├── 20-configure-users.sh
│       ├── 30-desktop-setup.sh
│       └── 40-cleanup.sh
│
├── iso/
│   ├── overlay/
│   │   └── etc/
│           └── skel/                # May contain some initial skel structure, but logic is moving
│                                    # toward syncing from dotfiles rather than editing here directly
│
│
├── manifests/
│   ├── apt-packages.base.txt        # Core utilities: zsh, binutils (strings), exiftool, etc.
│   ├── apt-packages.gui.txt         # Sway, XFCE, GUI tools
│   ├── apt-packages.dfir.txt        # DFIR tools: sleuthkit, Autopsy, regripper, etc.
│   ├── apt-packages.netsec.txt      # Netsec tools: nmap, masscan, wireshark, etc.
│   ├── brew-packages.txt            # Homebrew packages (e.g. Waveterm, Fastfetch - these are key and we'll need to run commands after brew install to add to PATH and configure things once we get packages)
│   ├── flatpak-apps.txt             # Flatpak apps (none currently)
│   └── pipx-tools.txt               # Python CLIs to install via pipx (impacket, wtfis, etc.)
│
├── scripts/
│   ├── build-iso.sh                 # Orchestrator: the main entrypoint for building PurplePop ISO
│   ├── download-base.sh             # Downloads Pop!_OS 22.04 ISO (needs real URL/checksum)
│   ├── create-chroot.sh             # Extracts ISO, unsquashes filesystem, mounts chroot
│   ├── install-tooling.sh           # Installs manifests’ packages inside chroot
│   ├── apply-overlays.sh            # Applies iso/overlay and syncs dotfiles into /etc/skel
│   ├── finalize-image.sh            # Unmounts chroot, rebuilds squashfs, and creates final ISO
│   ├── flash-usb.sh                 # Optional; not required because Etcher/Rufus will be used
│   └── helpers/
│       ├── detect-ubuntu-version.sh # Helper (not currently central)
│       └── log.sh                   # Logging helper (if used)
│
├── LICENSE
├── README.md
└── file-structure.txt               # Older file/tree log; can be updated or replaced by docs
```

---

### 5. Build Pipeline (Scripts & Order)

The intended build flow on a Linux host is:

1. **`scripts/build-iso.sh`**
   The main script. It orchestrates everything:

   * Calls `download-base.sh`
   * Calls `create-chroot.sh`
   * Calls `install-tooling.sh`
   * Calls `apply-overlays.sh`
   * (Future) Calls `configure-users-and-desktop.sh` or files in `image/filesystem-hooks/`
   * Calls `finalize-image.sh`

2. **`scripts/download-base.sh`**

   * Reads metadata from `image/base-popos.yaml` (or hardcoded for now)
   * Downloads the official Pop!_OS 22.04 ISO into `.build/base/`
   * Should optionally verify checksum using `sha256sum`

3. **`scripts/create-chroot.sh`**

   * Extracts the ISO into `.build/iso-root/` using `bsdtar`
   * Unsquashes `casper/filesystem.squashfs` into `.build/chroot/` using `unsquashfs`
   * Binds `/dev`, `/dev/pts`, `/proc`, `/sys`, `/run` into the chroot

4. **`scripts/install-tooling.sh`**

   * Copies `manifests/*.txt` into the chroot at `/manifests`
   * Runs `apt-get update` inside chroot
   * Iterates over `apt-packages*.txt` to install apt packages
   * Installs `pipx` and then `pipx-tools` if `pipx-tools.txt` is present
   * Cleans apt cache in chroot

5. **`scripts/apply-overlays.sh`** (recently updated design)
   Responsibilities:

   * `rsync` everything from `iso/overlay/` into the chroot
   * Populate `/etc/skel` inside chroot from `dotfiles/`:

     * `dotfiles/zsh` → `/etc/skel/.zshrc` and `/etc/skel/.config/zsh/*`
     * `dotfiles/sway` → `/etc/skel/.config/sway/`
     * `dotfiles/waybar` → `/etc/skel/.config/waybar/`
     * `dotfiles/xfce` → `/etc/skel/.config/xfce4/...`
     * `dotfiles/waveterm` → `/etc/skel/.config/waveterm/`
     * `dotfiles/git/.gitconfig` → `/etc/skel/.gitconfig`
   * Ensure `/usr/local/bin` in chroot is `a+rx` so helper scripts are executable

   **Important convention:**
   `dotfiles/` is the *canonical* source of truth; `/etc/skel` contents are derived from it, not edited directly in the overlay.

6. **`scripts/finalize-image.sh`**

   * Unmounts `dev/pts`, `dev`, `proc`, `sys`, `run` from chroot
   * Rebuilds `casper/filesystem.squashfs` with `mksquashfs`
   * Updates `casper/filesystem.size`
   * Uses `xorriso` (or similar) to generate a new ISO into `out/PurplePop-YYYYMMDD.iso`

7. **Flashing**

   * Out of scope for this repo/CI
   * User will use BalenaEtcher or Rufus with the ISO artifact

---

### 6. Current Status & Known Gaps

As of now, several pieces are **in place**, and a few are **incomplete / TODO**:

**Already in good shape:**

* `dotfiles/` for Sway, Waybar, XFCE, zsh, Waveterm
* `manifests/` with base, GUI, DFIR, and netsec packages
* GitHub Actions workflow at `.github/workflows/build-purplepop.yml`
* Basic build pipeline scripts: `build-iso.sh`, `create-chroot.sh`, `install-tooling.sh`, `apply-overlays.sh`, `finalize-image.sh` (skeletons provided)

**Needs attention / completion:**

1. **`image/base-popos.yaml` and `scripts/download-base.sh`**

   * Has been filled with the **real** Pop!_OS 22.04 ISO URL and checksum is commented out, logic should be put in to verify it.
   * Could be improved to actually parse the YAML, or just keep them in sync manually.

2. **User & session configuration**

   * Need a script (e.g. `scripts/configure-users-and-desktop.sh` or `image/filesystem-hooks/20-configure-users.sh`) that:

     * Creates the live user (name TBD, e.g. `purplepop` or `liveuser`)
     * Sets its shell to `/usr/bin/zsh`
     * Ensures it uses the `/etc/skel` content
     * Configures LightDM to:

       * Use `lightdm-gtk-greeter`
       * Offer Sway + XFCE sessions
       * Set a default session

3. **Bootloader specifics**

   * Currently, rebuild of ISO uses generic `xorriso` invocation.
   * We might need adjustments to preserve Pop!_OS bootloader behavior perfectly (systemd-boot / GRUB details).
   * `iso/config/grub.cfg` and `iso/config/isolinux.cfg` are placeholders and may be unused or removed.

4. **Filesystem hooks**

   * `image/filesystem-hooks/10-40-*.sh` are present but mostly stubs. Either:

     * Wire them into the pipeline, or
     * Remove them / repurpose them as wrappers around the existing scripts.

5. **Testing & Debugging helpers**

   * No explicit test harness exists yet (e.g. dry-run mode, size checks, etc.).
   * Might be useful to add logging, verbosity flags, or a “minimal build” target for faster iteration.

---

### 7. How a New Assistant Should Work With This

When you (assistant) are asked to continue work on PurplePop, you should:

1. **Respect the existing conventions:**

   * `dotfiles/` is source of truth; `/etc/skel` is derived.
   * `manifests/*.txt` drive what gets installed.
   * The build pipeline order is: download → extract → chroot → install → overlay/dotfiles → finalize.

2. **When adding features:**

   * Prefer to add/modify files in `dotfiles/`, `manifests/`, and `scripts/`, not random new locations.
   * Keep the repo tree coherent; if you add new scripts or tooling, update docs / comments accordingly.

3. **When updating the build pipeline:**

   * Make sure `scripts/build-iso.sh` remains the **one true entrypoint** for building.
   * If you split new logic into extra scripts, plug them into `build-iso.sh` in a clear, documented order.

4. **When asked for TODOs / next tasks:**

   * Suggest focused improvements like:

     * Completing user creation & LightDM config
     * Hardening `download-base.sh` and adding checksum verification
     * Adding documentation in `docs/` (BUILD, USAGE, CONTRIBUTING)

---

Tasks to prioritize:

* Implement or refine specific scripts (e.g. `configure-users-and-desktop.sh`)
* Adjust manifests
* Tweak dotfiles
* Improve CI
* Help debug issues in the build pipeline once we do a first test run.
