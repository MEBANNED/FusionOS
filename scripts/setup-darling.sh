#!/usr/bin/env bash
# ===========================================================================
# FusionOS — Darling (macOS Binary Compatibility) Builder
# ===========================================================================
# Darling is EXPERIMENTAL. This script compiles it from source and installs
# it as an opt-in feature.
#
# Usage:  chmod +x setup-darling.sh && sudo ./setup-darling.sh
# ===========================================================================
set -euo pipefail

echo "============================================="
echo "  FusionOS — macOS Compatibility (Darling)"
echo "  ⚠  EXPERIMENTAL — pre-alpha software"
echo "============================================="

# ── Step 1 : Install build dependencies ───────────────────────────────────
echo "[1/4] Installing build dependencies..."

apt-get update
apt-get install -y \
    cmake clang-15 bison flex pkg-config \
    libfuse-dev libudev-dev linux-headers-"$(uname -r)" \
    libcairo2-dev libfreetype-dev libxml2-dev \
    libbsd-dev libglu1-mesa-dev libssl-dev \
    libc6-dev-i386 libelf-dev \
    python3 git

# ── Step 2 : Clone Darling source ─────────────────────────────────────────
echo "[2/4] Cloning Darling repository..."

DARLING_SRC="/opt/darling-src"
if [ -d "${DARLING_SRC}" ]; then
    rm -rf "${DARLING_SRC}"
fi
git clone --recursive https://github.com/darlinghq/darling.git "${DARLING_SRC}"

# ── Step 3 : Build ────────────────────────────────────────────────────────
echo "[3/4] Building Darling (this may take 30+ minutes)..."

cd "${DARLING_SRC}"
mkdir -p build && cd build
cmake .. -DCMAKE_C_COMPILER=clang-15 -DCMAKE_CXX_COMPILER=clang++-15
make -j"$(nproc)"

echo "[3/4] Installing Darling..."
make install

# ── Step 4 : Build the kernel module ──────────────────────────────────────
echo "[4/4] Building Darling kernel module..."

cd "${DARLING_SRC}/build"
make lkm
make lkm_install
modprobe darling-mach || echo "⚠ Could not load kernel module — reboot may be needed."

echo ""
echo "============================================="
echo "  ✅  Darling installed (experimental)"
echo ""
echo "  Start a macOS shell:   darling shell"
echo "  Run a Mach-O binary:   darling /path/to/binary"
echo ""
echo "  ⚠  Many macOS apps will NOT work yet."
echo "  Track progress: https://github.com/darlinghq/darling"
echo "============================================="
