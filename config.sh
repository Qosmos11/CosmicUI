#!/bin/bash
ROM_VERSION="0.1-beta"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$ROOT_DIR/workspace"
NODE_DIR="$WORK_DIR/firmwares/$CURRENT_MODE"

DOWNLOAD_DIR="$NODE_DIR/downloads"
FINAL_ZIP="$DOWNLOAD_DIR/firmware.zip"

UNPACK_DIR="$NODE_DIR/unpacked"
SUPER_IMG="$UNPACK_DIR/super.img"
RAW_SUPER_IMG="$UNPACK_DIR/super.img.raw"

EXTRACT_DIR="$NODE_DIR/extracted"
ROOTFS_DIR="$NODE_DIR/rootfs"
METADATA_DIR="$NODE_DIR/metadata"

STOCK_UNPACK="$WORK_DIR/firmwares/$TARGET/unpacked"
STOCK_ROOTFS="$WORK_DIR/firmwares/$TARGET/rootfs"
STOCK_META="$WORK_DIR/firmwares/$TARGET/metadata"

DONOR_UNPACK="$WORK_DIR/firmwares/$BASE/unpacked"
DONOR_ROOTFS="$WORK_DIR/firmwares/$BASE/rootfs"
DONOR_META="$WORK_DIR/firmwares/$BASE/metadata"

PORT_DIR="$WORK_DIR/port"
PORT_ROOTFS="$PORT_DIR/rootfs"
PORT_META="$PORT_DIR/metadata"

OUTPUT_DIR="$WORK_DIR/output"