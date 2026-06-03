# FusionOS

A custom Linux distribution that blends the best of macOS and Windows into one polished desktop.

## Prerequisites

You need a **Debian 12 (Bookworm)** environment to build the ISO. If you don't already have one, follow the guide for your OS below to set one up first.

<details>
<summary><strong>I don't have a Linux machine (click to expand)</strong></summary>

You'll need to create a temporary Debian 12 virtual machine to use as your "build factory."

1. Download the official **Debian 12 (Bookworm)** ISO from the [Debian Archives](https://cdimage.debian.org/cdimage/archive/). (Navigate to the highest 12.14.0 version folder -> amd64(for intel devices) or ARM64 (for ARM devices or Apple Silicon Macs). -> iso-cd, and download the `netinst.iso`).
2. Install it in a VM using one of these apps:
   - **macOS**: [UTM](https://mac.getutm.app/) (free) or [VMware Fusion](https://www.vmware.com/products/fusion.html)
**Note**: For VMware Fusion, log into you Broadcom account, navigate to "My downloads" and click on the link saying "Free downloads available here" and find VMware Fusion Pro
   - **Windows**: [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html) (free) or [VirtualBox](https://www.virtualbox.org/)
3. During the Debian install, select the **standard system utilities** and **SSH server** options. A desktop environment is not required.
4. Once Debian is running, open a terminal inside it and continue with the Quick Start below.

</details>

## Quick Start

### 1. Get the source (On your Debian 12 machine)


# If you are using a minimal Debian ISO, you may need to install git first:
```bash
# su -
# apt update
# apt install git -y
```
# Then clone the repository:
```bash
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

### 3. Install on a real computer

This is the recommended way to experience FusionOS at full performance.

**What you need:**
- A USB flash drive (4 GB or larger)
- A tool to flash the ISO to USB:
  - **Windows**: [Rufus](https://rufus.ie/) or [balenaEtcher](https://etcher.balena.io/)
  - **macOS**: [balenaEtcher](https://etcher.balena.io/) or the `dd` command(not recomended, see below)
  - **Linux**: [balenaEtcher](https://etcher.balena.io/), GNOME Disks, or `dd`(not recomended, see below)

**Steps:**

1. **Flash the ISO to your USB drive.**

   Using balenaEtcher (all platforms):
   1. Open balenaEtcher.
   2. Click **Flash from file** and select `fusionos-1.0-amd64.iso`.
   3. Select your USB drive.
   4. Click **Flash** and wait for it to finish.

   Using `dd` (not recomended, macOS/Linux terminal)
   Disclaimer: By proceeding, you acknowledge and agree that FusionOS and its creators shall not be held liable for any data loss, corrupted files, or hardware damage resulting from the selection or erasure of an incorrect disk. It is the user’s sole responsibility to backup all data prior to formatting.
   ```bash
   # Find your USB drive (e.g. /dev/diskX on macOS, /dev/sdX on Linux)
   # ⚠️  MAKE SURE you pick the right drive — this will erase it!
   sudo dd if=fusionos-1.0-amd64.iso of=/dev/sdX bs=4M status=progress
   sync
   ```

3. **Boot from the USB drive.**
   1. Plug the USB into the target computer.
   2. Restart and enter the boot menu (usually **F12**, **F2**, **Esc**, or **Del** — depends on your motherboard).
   3. Select the USB drive from the boot menu.
   4. FusionOS will boot into the live desktop.

4. **Install to the hard drive.**
   1. Once in the live desktop, open the **Calamares** installer (it should appear on the desktop or in the app menu).
   2. Follow the on-screen wizard to partition your drive, set your username, and install.
   3. Reboot and remove the USB when prompted.

> ⚠️ **Driver Disclaimer:** FusionOS does not ship with drivers for all hardware. If you install it on a physical machine, you may need to manually install drivers for your GPU, Wi-Fi adapter, or other peripherals. Use at your own risk.

---

### If you want to install on a virtual machine

If you'd rather test FusionOS without touching your real hardware, you can run it in a VM. Allocate at least **4 GB RAM**, **2 CPU cores**, and **20 GB disk space** for the best experience.

#### macOS

| App | How to install the ISO |
|---|---|
| **UTM** (free) | Click **+** → **Virtualize** → **Linux** → select the ISO as **Boot ISO Image** → **Play** |
| **VMware Fusion** | **File** → **New** → drag and drop the ISO → follow the wizard |

#### Windows

| App | How to install the ISO |
|---|---|
| **VMware Workstation Player** (free) | **Create a New Virtual Machine** → **Installer disc image file** → browse to the ISO → set OS to **Linux / Debian 64-bit** → finish wizard → **Play** |
| **VirtualBox** (free) | **New** → name it `FusionOS`, type **Linux**, version **Debian 64-bit** → create a 20 GB disk → **Settings** → **Storage** → attach the ISO to the empty disc → **Start** |
| **Hyper-V** (Pro/Enterprise) | **New** → **Virtual Machine** → point to the ISO → **Generation 2** → **Start** |

#### Linux

| App | How to install the ISO |
|---|---|
| **QEMU/KVM** | `qemu-system-x86_64 -cdrom fusionos-1.0-amd64.iso -m 4G -enable-kvm` |
| **GNOME Boxes** | Click **+** → **Create a virtual machine** → select the ISO → **Create** |
| **VirtualBox** | Same steps as the Windows guide above |

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
