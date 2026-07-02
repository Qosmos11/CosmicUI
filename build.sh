#!/bin/bash
# build.sh — Remove ai bloat

TARGET=$1
BASE=$2

# Проверка окружения
source "./config.sh"
source "./scripts/check_deps.sh"

# ====================================================
# STEP 1: BASE ROM (Donor)
# ====================================================
source "./source/$BASE/config.sh"
CURRENT_MODE="$BASE"
source "./config.sh"              # <-- Dynamically maps configuration to donor node directories
source "./scripts/download_fw.sh"
source "./scripts/unpack_fw.sh"
source "./scripts/unpack_img.sh"

# ====================================================
# STEP 2: TARGET ROM (Stock)
# ====================================================
source "./target/$TARGET/config.sh"
CURRENT_MODE="$TARGET"
source "./config.sh"              # <-- Dynamically maps configuration to target node directories
source "./scripts/download_fw.sh"
source "./scripts/unpack_fw.sh"
source "./scripts/unpack_img.sh"

# ====================================================
# STEP 3: MERGE & REPACK
# ====================================================
source "./config.sh"              # <-- Returns environment vars to base execution values
source "./scripts/patch_port.sh"
source "./scripts/repack_img.sh"

echo "[+] Done!"