#!/bin/bash
# target/a55/common/vintf-fix/patch.sh — Un1ca adapted VINTF framework patcher

# Map local paths using the unified global environment variables
VINTF_DIR="/system/system/etc/vintf"
PORT_VINTF_TARGET="$PORT_ROOTFS$VINTF_DIR"
STOCK_VINTF_SOURCE="$STOCK_ROOTFS$VINTF_DIR"

echo -e "${CL_YEL}    [Mod: vintf-fix] Harmonizing system VINTF capabilities...${CL_RST}"

# Ensure the destination directory exists inside the ported system image
sudo mkdir -p "$PORT_VINTF_TARGET"

# -------------------------------------------------------------------------
# 1. Compatibility Matrix Processing
# -------------------------------------------------------------------------
# If your target kitchen tree has a manual override patch, use it first.
# Otherwise, pull the device compatibility matrix directly from the stock A55 files.
if [ -f "$STOCK_VINTF_SOURCE/compatibility_matrix.device.xml" ]; then
    echo "        [*] Swapping with target stock device compatibility matrix..."
    sudo cp -a "$STOCK_VINTF_SOURCE/compatibility_matrix.device.xml" "$PORT_VINTF_TARGET/compatibility_matrix.device.xml"
else
    echo -e "${CL_RED}        [-] Warning: Target compatibility_matrix.device.xml not found!${CL_RST}"
fi

# -------------------------------------------------------------------------
# 2. System Manifest Processing
# -------------------------------------------------------------------------
if [ -f "$STOCK_VINTF_SOURCE/manifest.xml" ]; then
    echo "        [*] Swapping with target stock device manifest..."
    sudo cp -a "$STOCK_VINTF_SOURCE/manifest.xml" "$PORT_VINTF_TARGET/manifest.xml"
fi

# -------------------------------------------------------------------------
# 3. Synchronize Kitchen Metadata Records
# -------------------------------------------------------------------------
# We need to tell the repack engine to assign correct permissions to these paths
PORT_CFG="$PORT_META/unified_config-system"
STOCK_CFG="$STOCK_META/unified_config-system"

if [ -f "$STOCK_CFG" ] && [ -f "$PORT_CFG" ]; then
    echo "        [*] Aligning VINTF security and SELinux contexts..."
    TMP_MOD_CFG=$(mktemp)
    
    # Extract permission lines belonging to the VINTF folder from the stock config mapping
    grep -E "^${VINTF_DIR}" "$STOCK_CFG" > "$TMP_MOD_CFG"
    
    if [ -s "$TMP_MOD_CFG" ]; then
        TMP_MERGE=$(mktemp)
        cat "$PORT_CFG" "$TMP_MOD_CFG" > "$TMP_MERGE"
        
        # Deduplicate metadata lines ensuring the stock targets override donor targets
        tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/unified_config-system"
        rm -f "$TMP_MERGE"
        echo -e "${CL_GRN}        [+] VINTF configuration metadata mapped successfully.${CL_RST}"
    else
        rm -f "$TMP_MOD_CFG"
    fi
fi