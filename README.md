# FusionOS

A custom Linux distribution that blends the best of macOS and Windows into one polished desktop.

## Quick Start

### 1. Get the source (On your Debian 13 "Build" machine)

```bash
# Clone the repository
git clone https://github.com/MEBANNED/FusionOS.git
cd FusionOS
```

### 2. Build the bootable ISO

```bash
# Install build dependencies
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso \
     syslinux-efi grub-efi-amd64-bin grub-pc-bin git

# Run the master build script
chmod +x build-iso.sh
sudo ./build-iso.sh

# The ISO will be at: /opt/fusionos-build/fusionos-1.0-amd64.iso
```

### 3. Test the ISO (On your Mac)

If you have `qemu` installed:
```bash
qemu-system-x86_64 -cdrom fusionos-1.0-amd64.iso -m 4G -enable-kvm
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
