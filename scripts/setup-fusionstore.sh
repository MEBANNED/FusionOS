#!/usr/bin/env bash
# ===========================================================================
# FusionOS — Unified Package Manager Bootstrap
# ===========================================================================
# Sets up the FusionStore backend: Flatpak (Flathub), Snap, and APT are
# all available. KDE Discover is pre-configured as the unified GUI.
#
# Usage:  chmod +x setup-fusionstore.sh && sudo ./setup-fusionstore.sh
# ===========================================================================
set -euo pipefail

echo "============================================="
echo "  FusionOS — FusionStore Setup"
echo "============================================="

# ── Step 1 : Flatpak ──────────────────────────────────────────────────────
echo "[1/4] Configuring Flatpak + Flathub..."

apt-get install -y flatpak plasma-discover-backend-flatpak

flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

# Pre-install popular Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform//23.08 || true
flatpak install -y flathub org.kde.Platform//6.6 || true

# ── Step 2 : Snap ─────────────────────────────────────────────────────────
echo "[2/4] Configuring Snap..."

apt-get install -y snapd
systemctl enable snapd.socket 2>/dev/null || true

# Snap needs a symlink for classic confinement
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

# Install the plasma-discover snap backend
apt-get install -y plasma-discover-backend-snap || true

# ── Step 3 : APT / PackageKit ─────────────────────────────────────────────
echo "[3/4] Configuring PackageKit for APT backend..."

apt-get install -y packagekit plasma-discover-backend-fwupd

# Enable automatic security updates
apt-get install -y unattended-upgrades apt-listchanges
dpkg-reconfigure -f noninteractive unattended-upgrades || true

# ── Step 4 : KDE Discover branding ────────────────────────────────────────
echo "[4/4] Applying FusionStore branding to Discover..."

DISCOVER_CONFIG="/etc/xdg/FusionStorerc"
cat > "${DISCOVER_CONFIG}" <<'CFGEOF'
[Global]
# Priority order for duplicate apps: Flatpak > APT > Snap
# This is handled by Discover's built-in dedup logic.

[FlatpakSources]
DefaultRemote=flathub

[SnapSources]
Enabled=true
CFGEOF

# Create a .desktop override to rebrand Discover as "FusionStore"
DESKTOP_DIR="/usr/share/applications"
if [ -f "${DESKTOP_DIR}/org.kde.discover.desktop" ]; then
    cp "${DESKTOP_DIR}/org.kde.discover.desktop" \
       "${DESKTOP_DIR}/fusionstore.desktop"
    sed -i 's/^Name=.*/Name=FusionStore/' \
        "${DESKTOP_DIR}/fusionstore.desktop"
    sed -i 's/^Comment=.*/Comment=Install and manage apps from Flatpak, APT, and Snap/' \
        "${DESKTOP_DIR}/fusionstore.desktop"
    sed -i 's/^Icon=.*/Icon=system-software-install/' \
        "${DESKTOP_DIR}/fusionstore.desktop"
fi

echo ""
echo "============================================="
echo "  ✅  FusionStore configured!"
echo ""
echo "  Open 'FusionStore' from the app launcher."
echo "  Backends: Flatpak (Flathub) · APT · Snap"
echo ""
echo "  CLI usage:"
echo "    flatpak search <app>"
echo "    apt search <app>"
echo "    snap find <app>"
echo "============================================="
