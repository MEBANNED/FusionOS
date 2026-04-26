# FusionOS

A custom Linux distribution that blends the best of macOS and Windows into one polished desktop.

## Quick Start

### Option A — Prototype on an existing Debian/Ubuntu machine

```bash
git clone <this-repo> fusionos && cd fusionos
chmod +x setup-desktop-prototype.sh
sudo ./setup-desktop-prototype.sh
# Log out → select "Plasma (Wayland)" at SDDM → log in
```

### Option B — Build a bootable ISO

```bash
# On a Debian 12 build host:
sudo apt install live-build debootstrap squashfs-tools xorriso \
     syslinux-efi grub-efi-amd64-bin grub-pc-bin

chmod +x build-iso.sh
sudo ./build-iso.sh

# Test the ISO:
qemu-system-x86_64 -cdrom /opt/fusionos-build/fusionos-1.0-amd64.iso -m 4G -enable-kvm
```

## Project Structure

```
fusionos/
├── build-iso.sh                         # Master ISO build script (live-build)
├── setup-desktop-prototype.sh           # Install DE on existing machine
├── config/
│   └── plasma/
│       ├── plasma-org.kde.plasma.desktop-appletsrc  # Panel layout (dock + top bar)
│       ├── kwinrc                                    # Window manager (blur, snapping)
│       ├── kdeglobals                                # Theme, fonts, colours
│       ├── krunnerrc                                 # Spotlight-like search
│       └── kglobalshortcutsrc                        # Keyboard shortcuts
├── scripts/
│   ├── setup-wine.sh                    # WINE + Proton-GE setup
│   ├── setup-darling.sh                 # Darling (macOS compat, experimental)
│   └── setup-fusionstore.sh             # Flatpak + Snap + APT unified store
└── installer/
    └── fusionos-installer.nsi           # NSIS Windows installer wrapper
```

## Key Features

| Feature | Implementation |
|---|---|
| macOS-style centred dock | KDE Plasma bottom panel + Icon-Only Task Manager |
| Global menu bar | KDE AppMenu widget on top panel |
| Windows system tray | KDE StatusNotifierItem (built-in) |
| Start menu + deep search | KDE Kickoff + KRunner (Alt+Space) |
| Window snapping | KWin tiling + electric borders |
| Mission Control | KWin Present Windows + Desktop Grid |
| Run .exe files | WINE + binfmt_misc (double-click works) |
| macOS binaries | Darling (experimental, opt-in) |
| Unified app store | KDE Discover rebranded as "FusionStore" |
| Time Machine snapshots | btrfs + Timeshift |

## License

MIT
