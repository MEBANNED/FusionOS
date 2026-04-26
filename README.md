# FusionOS

A custom Linux distribution that blends the best of macOS and Windows into one polished desktop.

## Prerequisites

You need a **Debian 13 (Trixie)** environment to build the ISO. If you don't already have one, follow the guide for your OS below to set one up first.

<details>
<summary><strong>I don't have a Linux machine (click to expand)</strong></summary>

You'll need to create a temporary Debian 13 virtual machine to use as your "build factory."

1. Download the official **Debian 13 (Trixie)** ISO from [debian.org/distrib](https://www.debian.org/distrib/).
2. Install it in a VM using one of these apps:
   - **macOS**: [UTM](https://mac.getutm.app/) (free) or [VMware Fusion](https://www.vmware.com/products/fusion.html)
   - **Windows**: [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html) (free) or [VirtualBox](https://www.virtualbox.org/)
3. During the Debian install, select the **standard system utilities** and **SSH server** options. A desktop environment is not required.
4. Once Debian is running, open a terminal inside it and continue with the Quick Start below.

</details>

## Quick Start

### 1. Get the source (On your Debian 13 machine)

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

### 3. Test/Install the ISO

Once you have the `.iso` file, copy it to your host machine and boot it in a VM.

#### macOS

**UTM (Recommended)**
1. Open UTM and click **+** to create a new VM.
2. Select **Virtualize** → **Linux**.
3. For the **Boot ISO Image**, browse and select `fusionos-1.0-amd64.iso`.
4. Allocate at least **4 GB RAM** and **2 CPU cores**.
5. Follow the prompts and click **Play**.

**VMware Fusion**
1. Select **File** → **New**.
2. Drag and drop the `fusionos-1.0-amd64.iso` onto the install window.
3. Allocate at least **4 GB RAM** and **2 CPU cores**.
4. Follow the wizard to create and start the VM.

#### Windows

**VMware Workstation Player (Recommended)**
1. Download and install [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html) (free for personal use).
2. Click **Create a New Virtual Machine**.
3. Select **Installer disc image file (iso)** and browse to `fusionos-1.0-amd64.iso`.
4. Set guest OS to **Linux** → **Debian 12/13 64-bit**.
5. Allocate at least **4 GB RAM** and **2 CPU cores**.
6. Finish the wizard and click **Play virtual machine**.

**VirtualBox**
1. Download and install [VirtualBox](https://www.virtualbox.org/).
2. Click **New**, name it `FusionOS`, set type to **Linux** and version to **Debian (64-bit)**.
3. Allocate at least **4 GB RAM**.
4. Create a virtual hard disk (20 GB+ recommended).
5. Go to **Settings** → **Storage**, click the empty disc icon, and select `fusionos-1.0-amd64.iso`.
6. Click **Start**.

**Hyper-V (Windows Pro/Enterprise only)**
1. Open **Hyper-V Manager** from the Start menu.
2. Click **New** → **Virtual Machine**.
3. Point the installation media to `fusionos-1.0-amd64.iso`.
4. Select **Generation 2**, allocate at least **4 GB RAM**.
5. Start the VM.

#### Linux

**QEMU/KVM (Command line)**
```bash
qemu-system-x86_64 -cdrom fusionos-1.0-amd64.iso -m 4G -enable-kvm
```

**GNOME Boxes**
1. Open Boxes -> Click **+** -> **Create a virtual machine**.
2. Select **Operating System Image File** and choose `fusionos-1.0-amd64.iso`.
3. Click **Create**.

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
