#!/usr/bin/env bash
# ===========================================================================
# FusionOS — Desktop Environment Prototype Setup (standalone)
# ===========================================================================
# Run this script on any existing Debian 12 / Ubuntu 22.04+ machine to
# install and configure the FusionOS desktop experience WITHOUT building
# a full ISO. Great for prototyping and iteration.
#
# Usage:
#   chmod +x setup-desktop-prototype.sh
#   sudo ./setup-desktop-prototype.sh
#   # Then log out, select "Plasma (Wayland)" at SDDM, and log in.
# ===========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================="
echo "  FusionOS Desktop Prototype Installer"
echo "============================================="
echo ""
echo "This will install and configure:"
echo "  • KDE Plasma 6 desktop environment"
echo "  • macOS-style global menu bar + centred dock"
echo "  • Windows-style system tray + snapping"
echo "  • WhiteSur icon & GTK themes"
echo "  • SierraBreeze window decorations"
echo "  • WINE for .exe compatibility"
echo "  • Flatpak + Snap + APT (FusionStore)"
echo ""
read -rp "Continue? [y/N] " REPLY
[[ "${REPLY}" =~ ^[Yy]$ ]] || exit 0

# ── 1. System update ─────────────────────────────────────────────────────
echo ""
echo "[1/8] Updating system packages..."
apt-get update && apt-get upgrade -y

# ── 2. Install KDE Plasma ────────────────────────────────────────────────
echo "[2/8] Installing KDE Plasma desktop..."
apt-get install -y \
    plasma-desktop plasma-workspace sddm sddm-theme-breeze \
    dolphin konsole kate ark gwenview okular spectacle kcalc \
    systemsettings plasma-nm plasma-pa bluedevil powerdevil kscreen \
    plasma-widgets-addons kdeplasma-addons \
    plasma-workspace-wayland xwayland xorg \
    kde-config-sddm kde-spectacle

systemctl enable sddm
systemctl set-default graphical.target

# ── 3. Install fonts ─────────────────────────────────────────────────────
echo "[3/8] Installing fonts (Inter, JetBrains Mono)..."
apt-get install -y fonts-inter fonts-jetbrains-mono || {
    # Fallback: download from Google Fonts
    mkdir -p /usr/share/fonts/truetype/inter /usr/share/fonts/truetype/jetbrains
    wget -qO /tmp/inter.zip "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
    unzip -qo /tmp/inter.zip -d /usr/share/fonts/truetype/inter
    wget -qO /tmp/jbmono.zip "https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono-2.304.zip"
    unzip -qo /tmp/jbmono.zip -d /usr/share/fonts/truetype/jetbrains
    fc-cache -fv
}

# ── 4. Install & apply themes ────────────────────────────────────────────
echo "[4/8] Installing themes (WhiteSur icons, GTK, cursor, SierraBreeze)..."

# WhiteSur icons
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme && ./install.sh -d /usr/share/icons -t default
cd /tmp && rm -rf WhiteSur-icon-theme

# WhiteSur GTK theme (for GTK apps running under Plasma)
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme && ./install.sh -c Dark -s standard -l -N mojave
cd /tmp && rm -rf WhiteSur-gtk-theme

# SierraBreeze Enhanced (macOS traffic-light window buttons)
apt-get install -y cmake extra-cmake-modules build-essential \
    libkdecorations2-dev libkf5config-dev libkf5coreaddons-dev \
    libkf5guiaddons-dev libkf5windowsystem-dev qtdeclarative5-dev gettext || true

cd /tmp
git clone --depth=1 https://github.com/kupiqu/SierraBreezeEnhanced.git 2>/dev/null || \
git clone --depth=1 https://github.com/ishovkun/SierraBreeze.git SierraBreezeEnhanced
cd SierraBreezeEnhanced
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j"$(nproc)" && make install
cd /tmp && rm -rf SierraBreezeEnhanced

# ── 5. Deploy KDE dotfiles ───────────────────────────────────────────────
echo "[5/8] Deploying FusionOS Plasma configuration..."

# Copy configs to /etc/skel (new users) and current user's home
for TARGET_DIR in "/etc/skel/.config" "${HOME}/.config"; do
    mkdir -p "${TARGET_DIR}"
    if [ -d "${SCRIPT_DIR}/config/plasma" ]; then
        cp -v "${SCRIPT_DIR}/config/plasma/plasma-org.kde.plasma.desktop-appletsrc" \
              "${TARGET_DIR}/" 2>/dev/null || true
        cp -v "${SCRIPT_DIR}/config/plasma/kwinrc" \
              "${TARGET_DIR}/" 2>/dev/null || true
        cp -v "${SCRIPT_DIR}/config/plasma/kdeglobals" \
              "${TARGET_DIR}/" 2>/dev/null || true
        cp -v "${SCRIPT_DIR}/config/plasma/krunnerrc" \
              "${TARGET_DIR}/" 2>/dev/null || true
        cp -v "${SCRIPT_DIR}/config/plasma/kglobalshortcutsrc" \
              "${TARGET_DIR}/" 2>/dev/null || true
    else
        echo "  ⚠ Config directory not found at ${SCRIPT_DIR}/config/plasma"
        echo "    Make sure you run this script from the fusionos repo root."
    fi
done

# ── 6. WINE setup ────────────────────────────────────────────────────────
echo "[6/8] Setting up WINE..."
if [ -f "${SCRIPT_DIR}/scripts/setup-wine.sh" ]; then
    bash "${SCRIPT_DIR}/scripts/setup-wine.sh"
else
    apt-get install -y wine wine64 winetricks binfmt-support
fi

# ── 7. FusionStore (package management) ──────────────────────────────────
echo "[7/8] Setting up FusionStore..."
if [ -f "${SCRIPT_DIR}/scripts/setup-fusionstore.sh" ]; then
    bash "${SCRIPT_DIR}/scripts/setup-fusionstore.sh"
else
    apt-get install -y flatpak snapd plasma-discover-backend-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ── 8. Firefox ────────────────────────────────────────────────────────────
echo "[8/8] Ensuring Firefox is installed..."
apt-get install -y firefox-esr

echo ""
echo "============================================="
echo "  ✅  FusionOS Desktop Prototype installed!"
echo ""
echo "  Next steps:"
echo "    1. Log out of your current session"
echo "    2. At the SDDM login screen, select"
echo "       'Plasma (Wayland)' or 'Plasma (X11)'"
echo "    3. Log in and enjoy!"
echo ""
echo "  To tweak further:"
echo "    • System Settings → Appearance"
echo "    • Right-click desktop → Configure Desktop"
echo "    • Right-click panel → Edit Panel"
echo "============================================="
