#!/bin/bash

VINTF_DIR="/system/system/etc/vintf"
PORT_VINTF_TARGET="$PORT_ROOTFS$VINTF_DIR"
STOCK_VINTF_SOURCE="$STOCK_ROOTFS$VINTF_DIR"

sudo mkdir -p "$PORT_VINTF_TARGET"

if [ -f "$STOCK_VINTF_SOURCE/compatibility_matrix.device.xml" ]; then
    echo "Swapping compatibility matrix"
    sudo cp -a "$STOCK_VINTF_SOURCE/compatibility_matrix.device.xml" "$PORT_VINTF_TARGET/compatibility_matrix.device.xml"
else
    echo "compatibility_matrix.device.xml not found!"
fi

if [ -f "$STOCK_VINTF_SOURCE/manifest.xml" ]; then
    echo "Swapping with target stock device manifest..."
    sudo cp -a "$STOCK_VINTF_SOURCE/manifest.xml" "$PORT_VINTF_TARGET/manifest.xml"
fi

PORT_CFG="$PORT_META/unified_config-system"
STOCK_CFG="$STOCK_META/unified_config-system"

if [ -f "$STOCK_CFG" ] && [ -f "$PORT_CFG" ]; then
    echo "Aligning SELinux contexts."
    TMP_MOD_CFG=$(mktemp)
    grep -E "^${VINTF_DIR}" "$STOCK_CFG" > "$TMP_MOD_CFG"
    
    if [ -s "$TMP_MOD_CFG" ]; then
        TMP_MERGE=$(mktemp)
        cat "$PORT_CFG" "$TMP_MOD_CFG" > "$TMP_MERGE"
        
        # Deduplicate metadata lines ensuring the stock targets override donor targets
        tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/unified_config-system"
        rm -f "$TMP_MERGE"
    else
        rm -f "$TMP_MOD_CFG"
    fi
fi