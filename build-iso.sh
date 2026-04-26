#!/usr/bin/env bash
# ===========================================================================
# FusionOS — Master ISO Build Script
# ===========================================================================
# This script builds a live, bootable .iso from a clean Debian 12 base
# using the official `live-build` toolchain.
#
# Prerequisites (run on a Debian 12 / Ubuntu 22.04+ build host):
#   sudo apt install live-build debootstrap squashfs-tools xorriso
#   sudo apt install syslinux-efi grub-efi-amd64-bin grub-pc-bin
#
# Usage:
#   chmod +x build-iso.sh
#   sudo ./build-iso.sh
# ===========================================================================
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
DISTRO_NAME="FusionOS"
DISTRO_VERSION="1.0"
WORK_DIR="/opt/fusionos-build"
CONFIG_SRC="$(cd "$(dirname "$0")" && pwd)"   # path to this repo root
ARCH="amd64"
DEBIAN_MIRROR="http://deb.debian.org/debian"
DEBIAN_SUITE="trixie"                        # Changed to Trixie for Debian 13 support
KERNEL_FLAVOUR="amd64"

echo "============================================="
echo "  ${DISTRO_NAME} ${DISTRO_VERSION} ISO Builder"
echo "============================================="

# ── Step 1 : Clean workspace ──────────────────────────────────────────────
if [ -d "${WORK_DIR}" ]; then
    echo "[*] Cleaning previous build..."
    rm -rf "${WORK_DIR}"
fi
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# ── Step 2 : Initialise live-build config ──────────────────────────────────
echo "[*] Configuring live-build..."

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
echo "[*] Writing package lists..."

mkdir -p config/package-lists

# ---------- Core System ----------
cat > config/package-lists/01-core.list.chroot <<'PKGEOF'
# Kernel & firmware
linux-image-amd64
firmware-linux
firmware-misc-nonfree
firmware-iwlwifi
firmware-realtek
firmware-atheros
intel-microcode
amd64-microcode

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

# Filesystem & boot
btrfs-progs
grub-efi-amd64
efibootmgr
os-prober
timeshift

# Basic CLI tools
bash-completion
curl
wget
git
htop
fastfetch
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

# ---------- App Compatibility ----------
cat > config/package-lists/03-appcompat.list.chroot <<'PKGEOF'
# WINE (Windows .exe compatibility)
wine
wine64
winetricks

# Flatpak & Snap support
flatpak
plasma-discover-backend-flatpak
snapd

# Misc app-compat
binfmt-support
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
set -e
echo "[FusionOS] Building SierraBreeze Enhanced..."

apt-get install -y cmake extra-cmake-modules build-essential \
    libkdecorations2-dev libkf5config-dev libkf5coreaddons-dev \
    libkf5guiaddons-dev libkf5windowsystem-dev qtdeclarative5-dev \
    gettext || true

cd /tmp
git clone --depth=1 https://github.com/kupiqu/SiesrraBreezeEnhanced.git || \
git clone --depth=1 https://github.com/ishovkun/SierraBreeze.git SierraBreezeEnhanced

cd SierraBreezeEnhanced
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j"$(nproc)"
make install
cd /tmp && rm -rf SierraBreezeEnhanced

echo "[FusionOS] SierraBreeze installed."
HOOKEOF
chmod +x config/hooks/live/02-sierrabreeze.hook.chroot

# ------- 4c. Flatpak + WINE configuration -------
cat > config/hooks/live/03-appcompat-setup.hook.chroot <<'HOOKEOF'
#!/bin/bash
set -e
echo "[FusionOS] Configuring Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "[FusionOS] Configuring WINE binfmt (so .exe double-click works)..."
cat > /usr/share/binfmts/wine <<'BINFMT'
package wine
interpreter /usr/bin/wine
magic MZ
BINFMT
update-binfmts --import wine || true

echo "[FusionOS] AppCompat setup complete."
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
echo "  Building ISO — this will take 15-45 min"
echo "============================================="

lb build 2>&1 | tee build.log

# ── Step 9 : Rename output ISO ────────────────────────────────────────────
ISO_FILE=$(ls -1 live-image-*.hybrid.iso 2>/dev/null | head -1)
if [ -n "${ISO_FILE}" ]; then
    FINAL_NAME="fusionos-${DISTRO_VERSION}-${ARCH}.iso"
    mv "${ISO_FILE}" "${FINAL_NAME}"
    echo ""
    echo "============================================="
    echo "  ✅  ISO built successfully!"
    echo "  📦  ${WORK_DIR}/${FINAL_NAME}"
    echo "  📏  $(du -h "${FINAL_NAME}" | cut -f1)"
    echo "============================================="
    echo ""
    echo "  To test:  qemu-system-x86_64 -cdrom ${FINAL_NAME} -m 4G -enable-kvm"
    echo "  To flash: sudo dd if=${FINAL_NAME} of=/dev/sdX bs=4M status=progress"
else
    echo "❌ Build failed — check build.log for details."
    exit 1
fi
