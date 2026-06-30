#!/bin/bash
# config.sh — Deeply Unified Global Environment Configurations

# Цветовая палитра для терминала
CL_RST="\e[0m"
CL_RED="\e[31m"
CL_GRN="\e[32m"
CL_CYN="\e[36m"
CL_YEL="\e[33m"

# Версия и корень кухни
ROM_VERSION="0.1-beta"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$ROOT_DIR/workspace"

# ====================================================
# 1. RAW FIRMWARE PIPELINE (Organized by Node)
# ====================================================
# All intermediate extraction stages are safely nested under a single 'firmwares' folder
NODE_DIR="$WORK_DIR/firmwares/$CURRENT_MODE"

DOWNLOAD_DIR="$NODE_DIR/downloads"
FINAL_ZIP="$DOWNLOAD_DIR/firmware.zip"
TMP_ENC_FILE="$DOWNLOAD_DIR/downloaded_base.enc4"
NO_EXT_FILE="$DOWNLOAD_DIR/downloaded_base"

UNPACK_DIR="$NODE_DIR/unpacked"
SUPER_IMG="$UNPACK_DIR/super.img"
RAW_SUPER_IMG="$UNPACK_DIR/super.img.raw"

EXTRACT_DIR="$NODE_DIR/extracted"
ROOTFS_DIR="$NODE_DIR/rootfs"
METADATA_DIR="$NODE_DIR/metadata"

# ====================================================
# 2. STATIC PATHS FOR MERGING & PORTING
# ====================================================
# Point to the unified internal structures of TARGET and BASE nodes
STOCK_UNPACK="$WORK_DIR/firmwares/$TARGET/unpacked"
STOCK_ROOTFS="$WORK_DIR/firmwares/$TARGET/rootfs"
STOCK_META="$WORK_DIR/firmwares/$TARGET/metadata"

DONOR_UNPACK="$WORK_DIR/firmwares/$BASE/unpacked"
DONOR_ROOTFS="$WORK_DIR/firmwares/$BASE/rootfs"
DONOR_META="$WORK_DIR/firmwares/$BASE/metadata"

# ====================================================
# 3. UNIFIED PORT ENGINE & OUTPUT TARGETS
# ====================================================
# Your single point of interest when porting
PORT_DIR="$WORK_DIR/port"
PORT_ROOTFS="$PORT_DIR/rootfs"
PORT_META="$PORT_DIR/metadata"

OUTPUT_DIR="$WORK_DIR/output"