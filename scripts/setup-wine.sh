#!/usr/bin/env bash
# ===========================================================================
# FusionOS — WINE / Proton Compatibility Setup
# ===========================================================================
# Run this on a live FusionOS system (or inside the chroot) to fully
# configure WINE for seamless .exe execution.
#
# Usage:  chmod +x setup-wine.sh && sudo ./setup-wine.sh
# ===========================================================================
set -euo pipefail

echo "============================================="
echo "  FusionOS — Windows Compatibility Setup"
echo "============================================="

# ── Step 1 : Add WineHQ official repository for latest builds ────────────
echo "[1/5] Adding WineHQ repository..."

dpkg --add-architecture i386

mkdir -pm755 /etc/apt/keyrings
wget -qO /etc/apt/keyrings/winehq-archive.key \
    https://dl.winehq.org/wine-builds/winehq.key

wget -qNP /etc/apt/sources.list.d/ \
    "https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources"

apt-get update

# ── Step 2 : Install WINE Staging ─────────────────────────────────────────
echo "[2/5] Installing WINE staging..."
apt-get install -y --install-recommends winehq-staging

# ── Step 3 : Install Winetricks ───────────────────────────────────────────
echo "[3/5] Installing Winetricks..."
apt-get install -y winetricks cabextract

# ── Step 4 : Register .exe with binfmt_misc ──────────────────────────────
echo "[4/5] Registering .exe files with binfmt_misc..."

# Create binfmt entry so double-clicking .exe files runs them with WINE
cat > /usr/share/binfmts/wine <<'EOF'
package wine
interpreter /usr/bin/wine
magic MZ
EOF

update-binfmts --import wine 2>/dev/null || true

# Also create a desktop entry for the context menu
mkdir -p /usr/share/applications
cat > /usr/share/applications/wine-open.desktop <<'EOF'
[Desktop Entry]
Name=Run with Windows Compatibility
Comment=Execute Windows .exe files using WINE
Exec=wine %f
Type=Application
MimeType=application/x-ms-dos-executable;application/x-msdos-program;
Icon=wine
NoDisplay=true
Terminal=false
EOF

# Register MIME association
cat > /usr/share/mime/packages/wine.xml <<'MIMEEOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-ms-dos-executable">
    <comment>Windows Executable</comment>
    <glob pattern="*.exe"/>
  </mime-type>
</mime-info>
MIMEEOF
update-mime-database /usr/share/mime 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true

# ── Step 5 : Install Proton-GE (standalone, for non-Steam games) ─────────
echo "[5/5] Installing Proton-GE..."

PROTON_DIR="/opt/proton-ge"
mkdir -p "${PROTON_DIR}"

# Get latest Proton-GE release
LATEST_URL=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
    | grep "browser_download_url.*tar.gz" | head -1 | cut -d'"' -f4)

if [ -n "${LATEST_URL}" ]; then
    wget -qO /tmp/proton-ge.tar.gz "${LATEST_URL}"
    tar -xzf /tmp/proton-ge.tar.gz -C "${PROTON_DIR}" --strip-components=1
    rm /tmp/proton-ge.tar.gz
    echo "  Proton-GE installed to ${PROTON_DIR}"
else
    echo "  ⚠ Could not fetch Proton-GE release URL. Install manually later."
fi

echo ""
echo "============================================="
echo "  ✅  Windows compatibility layer configured!"
echo ""
echo "  • Double-click any .exe to run it"
echo "  • Use 'winetricks' to install runtimes:"
echo "      winetricks vcrun2019 dotnet48 dxvk"
echo "  • Proton-GE: ${PROTON_DIR}"
echo "============================================="
