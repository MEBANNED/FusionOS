#!/usr/bin/env bash
# ===========================================================================
# FusionOS — ARM64 ISO Build Script
# ===========================================================================
# This script builds a live, bootable .iso for ARM64 (aarch64) devices
# from a clean Debian 12 base using the official `live-build` toolchain.
#
# Supported targets:
#   • Apple Silicon Macs (via UTM / Asahi Linux)
#   • Raspberry Pi 4/5 (UEFI boot)
#   • Ampere / Graviton ARM servers
#   • Qualcomm Snapdragon laptops
#   • Any UEFI-capable ARM64 device
#
# Prerequisites (run on a Debian 12 ARM64 build host):
#   sudo apt install live-build debootstrap squashfs-tools xorriso
#   sudo apt install grub-efi-arm64-bin
#
# Usage:
#   chmod +x build-iso-arm64.sh
#   sudo ./build-iso-arm64.sh
# ===========================================================================
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
DISTRO_NAME="FusionOS"
DISTRO_VERSION="1.0"
WORK_DIR="/opt/fusionos-build"
CONFIG_SRC="$(cd "$(dirname "$0")" && pwd)"   # path to this repo root
ARCH="arm64"
DEBIAN_MIRROR="http://deb.debian.org/debian"
DEBIAN_SUITE="bookworm"                        # Debian 12
KERNEL_FLAVOUR="arm64"

echo "============================================="
echo "  ${DISTRO_NAME} ${DISTRO_VERSION} ISO Builder (ARM64)"
echo "============================================="

# ── Preflight : Verify we are on an ARM64 host ────────────────────────────
HOST_ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
if [[ "${HOST_ARCH}" != "arm64" && "${HOST_ARCH}" != "aarch64" ]]; then
    echo ""
    echo "  ⚠  WARNING: This build host is '${HOST_ARCH}', not arm64."
    echo "     Cross-building may work but is not officially supported."
    echo "     For best results, run this on a native ARM64 Debian machine."
    echo ""
    read -rp "  Continue anyway? [y/N] " REPLY
    [[ "${REPLY}" =~ ^[Yy]$ ]] || exit 0
fi

# ── Step 1 : Clean workspace ──────────────────────────────────────────────
if [ -d "${WORK_DIR}" ]; then
    echo "[*] Cleaning previous build..."
    rm -rf "${WORK_DIR}"
fi
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# ── Step 2 : Initialise live-build config ──────────────────────────────────
echo "[*] Configuring live-build for ARM64..."

lb config \
    --distribution "${DEBIAN_SUITE}" \
    --architectures "${ARCH}" \
    --archive-areas "main contrib non-free non-free-firmware" \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR}" \
    --mirror-binary "${DEBIAN_MIRROR}" \
    --linux-flavours "${KERNEL_FLAVOUR}" \
    --linux-packages "linux-image linux-headers" \
    --bootappend-live "boot=live components quiet splash" \
    --binary-images iso-hybrid \
    --iso-application "${DISTRO_NAME}" \
    --iso-publisher "${DISTRO_NAME} Project" \
    --iso-volume "${DISTRO_NAME} ${DISTRO_VERSION}" \
    --memtest none \
    --firmware-binary true \
    --firmware-chroot true \
    --apt-recommends true \
    --security true \
    --updates true \
    --debootstrap-options "--variant=minbase" \
    --system live \
    --interactive false

# ── Step 3 : Define package lists ──────────────────────────────────────────
echo "[*] Writing package lists (ARM64)..."

mkdir -p config/package-lists

# ---------- Core System ----------
cat > config/package-lists/01-core.list.chroot <<'PKGEOF'
# Kernel & firmware (ARM64)
linux-image-arm64
firmware-linux
firmware-misc-nonfree
firmware-realtek
firmware-atheros
firmware-brcm80211

# Base system
systemd
systemd-sysv
dbus-broker
network-manager
network-manager-gnome
bluez
pulseaudio
pipewire
pipewire-pulse
wireplumber
mesa-utils
xdg-utils
xdg-user-dirs
upower
udisks2
polkitd
gvfs
gvfs-backends

# Filesystem & boot (ARM64 UEFI)
btrfs-progs
grub-efi-arm64
efibootmgr
os-prober
timeshift

# Device-tree & ARM platform support
device-tree-compiler

# Basic CLI tools
bash-completion
curl
wget
git
htop
neofetch
nano
vim
unzip
p7zip-full
PKGEOF

# ---------- KDE Plasma Desktop ----------
cat > config/package-lists/02-desktop.list.chroot <<'PKGEOF'
# Plasma core
plasma-desktop
plasma-workspace
sddm
sddm-theme-breeze

# KDE applications
dolphin
konsole
kate
ark
gwenview
okular
# spectacle (merged into kde-spectacle in Trixie)
kcalc
kde-config-sddm
systemsettings
plasma-nm
plasma-pa
bluedevil
powerdevil
kscreen
kde-spectacle

# Panel & dock
plasma-widgets-addons

# Window decoration (SierraBreeze)
# Will be compiled from source in hook script

# Theming deps
papirus-icon-theme
breeze-cursor-theme
fonts-inter
fonts-jetbrains-mono

# Wayland & X11 (plasma-workspace-wayland merged into plasma-workspace in Trixie)
xwayland
xorg
PKGEOF

# ---------- App Compatibility (ARM64) ----------
cat > config/package-lists/03-appcompat.list.chroot <<'PKGEOF'
# Note: Native WINE is x86-only. On ARM64 we use Box64 + Wine to
# translate x86_64 Windows binaries. Box64 is installed from source
# in the chroot hook script below.

# Flatpak & Snap support
flatpak
plasma-discover-backend-flatpak
snapd

# Misc app-compat
binfmt-support
qemu-user-static
PKGEOF

# ---------- Extras ----------
cat > config/package-lists/04-extras.list.chroot <<'PKGEOF'
# Web browser
firefox-esr

# Media
vlc
ffmpeg

# Office (optional — can be installed via Flatpak instead)
# libreoffice

# System install
calamares
calamares-settings-debian
PKGEOF

# ── Step 4 : Chroot hook scripts ──────────────────────────────────────────
echo "[*] Writing chroot hook scripts..."

mkdir -p config/hooks/live

# ------- 4a. Theme & appearance setup -------
cat > config/hooks/live/01-theme-setup.hook.chroot <<'HOOKEOF'
#!/bin/bash
set -e
echo "[FusionOS] Installing theme dependencies..."
apt-get install -y sassc libglib2.0-dev libxml2-utils dialog || true

echo "[FusionOS] Installing WhiteSur icon theme..."
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git || true
if [ -d WhiteSur-icon-theme ]; then
    cd WhiteSur-icon-theme
    ./install.sh -d /usr/share/icons -t default || true
    cd /tmp && rm -rf WhiteSur-icon-theme
fi

echo "[FusionOS] Installing WhiteSur GTK theme..."
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git || true
if [ -d WhiteSur-gtk-theme ]; then
    cd WhiteSur-gtk-theme
    ./install.sh -c Dark -s standard -d /usr/share/themes || true
    cd /tmp && rm -rf WhiteSur-gtk-theme
fi

echo "[FusionOS] Installing macOS BigSur cursor..."
cd /tmp
git clone --depth=1 https://github.com/ful1e5/apple_cursor.git || true
if [ -d apple_cursor ]; then
    cp -r apple_cursor/macOS-BigSur /usr/share/icons/macOS-BigSur || true
    cd /tmp && rm -rf apple_cursor
fi

echo "[FusionOS] Theme installation complete."
HOOKEOF
chmod +x config/hooks/live/01-theme-setup.hook.chroot

# ------- 4b. SierraBreeze Enhanced (window decorations) -------
cat > config/hooks/live/02-sierrabreeze.hook.chroot <<'HOOKEOF'
#!/bin/bash
echo "[FusionOS] Building SierraBreeze Enhanced..."

apt-get install -y cmake extra-cmake-modules build-essential \
    libkdecorations2-dev libkf5config-dev libkf5coreaddons-dev \
    libkf5guiaddons-dev libkf5windowsystem-dev qtdeclarative5-dev \
    gettext || true

cd /tmp
git clone --depth=1 https://github.com/kupiqu/SierraBreezeEnhanced.git || \
git clone --depth=1 https://github.com/ishovkun/SierraBreeze.git SierraBreezeEnhanced

if [ -d SierraBreezeEnhanced ]; then
    cd SierraBreezeEnhanced
    mkdir -p build && cd build
    if cmake .. -DCMAKE_INSTALL_PREFIX=/usr; then
        make -j"$(nproc)" && make install
        echo "[FusionOS] SierraBreeze installed."
    else
        echo "[FusionOS] SierraBreeze build skipped (incompatible ECM version)."
    fi
    cd /tmp && rm -rf SierraBreezeEnhanced
else
    echo "[FusionOS] SierraBreeze clone failed, skipping."
fi

exit 0
HOOKEOF
chmod +x config/hooks/live/02-sierrabreeze.hook.chroot

# ------- 4c. Flatpak + Box64/Wine configuration (ARM64) -------
cat > config/hooks/live/03-appcompat-setup.hook.chroot <<'HOOKEOF'
#!/bin/bash
set -e

# ── Flatpak ──────────────────────────────────────────────────────────────
echo "[FusionOS] Configuring Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ── Box64 + Wine (x86_64 emulation on ARM64) ─────────────────────────────
echo "[FusionOS] Building Box64 for x86_64 emulation on ARM64..."

apt-get install -y cmake build-essential git python3 || true

# Install Box64 (translates x86_64 → ARM64)
cd /tmp
git clone --depth=1 https://github.com/ptitSeb/box64.git || true
if [ -d box64 ]; then
    cd box64
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
             -DARM_DYNAREC=ON
    make -j"$(nproc)" && make install
    systemctl restart systemd-binfmt 2>/dev/null || true
    cd /tmp && rm -rf box64
    echo "[FusionOS] Box64 installed."
else
    echo "[FusionOS] Box64 clone failed, skipping."
fi

# Install Box86 (translates x86 32-bit → ARM32)
cd /tmp
git clone --depth=1 https://github.com/ptitSeb/box86.git || true
if [ -d box86 ]; then
    cd box86
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
             -DARM_DYNAREC=ON
    make -j"$(nproc)" && make install
    systemctl restart systemd-binfmt 2>/dev/null || true
    cd /tmp && rm -rf box86
    echo "[FusionOS] Box86 installed."
else
    echo "[FusionOS] Box86 clone failed, skipping."
fi

# Install x86_64 Wine through Box64
# Download a pre-built x86_64 Wine binary that Box64 can translate
WINE_VERSION="9.0"
WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-amd64.tar.xz"
echo "[FusionOS] Downloading x86_64 Wine ${WINE_VERSION} for Box64..."

cd /tmp
wget -qO wine-x86_64.tar.xz "${WINE_URL}" || true
if [ -f wine-x86_64.tar.xz ]; then
    mkdir -p /opt/wine-x86_64
    tar -xf wine-x86_64.tar.xz -C /opt/wine-x86_64 --strip-components=1
    rm wine-x86_64.tar.xz

    # Create wrapper scripts so 'wine' commands work transparently
    cat > /usr/local/bin/wine <<'WINEEOF'
#!/bin/bash
# Wine wrapper — uses Box64 to translate x86_64 Wine on ARM64
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
BOX64_LOG=0 box64 /opt/wine-x86_64/bin/wine64 "$@"
WINEEOF
    chmod +x /usr/local/bin/wine

    cat > /usr/local/bin/wine64 <<'WINEEOF'
#!/bin/bash
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
BOX64_LOG=0 box64 /opt/wine-x86_64/bin/wine64 "$@"
WINEEOF
    chmod +x /usr/local/bin/wine64

    cat > /usr/local/bin/wineserver <<'WINEEOF'
#!/bin/bash
BOX64_LOG=0 box64 /opt/wine-x86_64/bin/wineserver "$@"
WINEEOF
    chmod +x /usr/local/bin/wineserver

    # Register .exe files with binfmt_misc via Box64+Wine
    cat > /usr/share/binfmts/wine <<'BINFMT'
package wine
interpreter /usr/local/bin/wine
magic MZ
BINFMT
    update-binfmts --import wine || true

    echo "[FusionOS] Wine (via Box64) installed to /opt/wine-x86_64"
else
    echo "[FusionOS] ⚠ Could not download Wine. Install manually later."
fi

echo "[FusionOS] ARM64 AppCompat setup complete."
HOOKEOF
chmod +x config/hooks/live/03-appcompat-setup.hook.chroot

# ------- 4d. Skeleton dotfiles for new users -------
cat > config/hooks/live/04-skel-dotfiles.hook.chroot <<'HOOKEOF'
#!/bin/bash
set -e
echo "[FusionOS] Installing default dotfiles into /etc/skel..."

SKEL_PLASMA="/etc/skel/.config"
mkdir -p "${SKEL_PLASMA}"

# These files will be placed by the lb build from config/includes.chroot
# This hook ensures correct ownership
chown -R root:root /etc/skel/.config || true

echo "[FusionOS] Skel dotfiles installed."
HOOKEOF
chmod +x config/hooks/live/04-skel-dotfiles.hook.chroot

# ── Step 5 : Copy dotfiles into chroot includes ──────────────────────────
echo "[*] Copying FusionOS dotfiles into chroot overlay..."

SKEL_TARGET="config/includes.chroot/etc/skel/.config"
mkdir -p "${SKEL_TARGET}"

# Copy all KDE plasma configs from our repo
if [ -d "${CONFIG_SRC}/config/plasma" ]; then
    cp -r "${CONFIG_SRC}/config/plasma/"* "${SKEL_TARGET}/"
fi

# ── Step 6 : SDDM (login screen) branding ────────────────────────────────
echo "[*] Configuring SDDM branding..."

mkdir -p config/includes.chroot/etc/sddm.conf.d

cat > config/includes.chroot/etc/sddm.conf.d/fusionos.conf <<'SDDMEOF'
[Theme]
Current=breeze

[General]
InputMethod=
Numlock=on

[Users]
MaximumUid=60000
MinimumUid=1000
SDDMEOF

# ── Step 7 : Plymouth boot splash placeholder ────────────────────────────
echo "[*] Plymouth boot splash — using default (replace with custom later)."

# ── Step 8 : Build the ISO ────────────────────────────────────────────────
echo "============================================="
echo "  Building ARM64 ISO — this will take 15-45 min"
echo "============================================="

lb build 2>&1 | tee build.log

# ── Step 9 : Rename output ISO ────────────────────────────────────────────
ISO_FILE=$(ls -1 live-image-*.hybrid.iso 2>/dev/null | head -1)
if [ -n "${ISO_FILE}" ]; then
    FINAL_NAME="fusionos-${DISTRO_VERSION}-${ARCH}.iso"
    mv "${ISO_FILE}" "${FINAL_NAME}"
    echo ""
    echo "============================================="
    echo "  ✅  ARM64 ISO built successfully!"
    echo "  📦  ${WORK_DIR}/${FINAL_NAME}"
    echo "  📏  $(du -h "${FINAL_NAME}" | cut -f1)"
    echo "============================================="
    echo ""
    echo "  To test (QEMU):"
    echo "    qemu-system-aarch64 -M virt -cpu cortex-a72 -m 4G \\"
    echo "      -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \\"
    echo "      -cdrom ${FINAL_NAME} -device virtio-gpu -device usb-ehci \\"
    echo "      -device usb-kbd -device usb-mouse"
    echo ""
    echo "  To flash (USB):"
    echo "    sudo dd if=${FINAL_NAME} of=/dev/sdX bs=4M status=progress"
else
    echo "❌ Build failed — check build.log for details."
    exit 1
fi
