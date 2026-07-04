#!/bin/bash
# target/a55/common/camera-fix/patch.sh — Camera Feature Harmonization Mod

CAM_DATA_DIR="/system/system/cameradata"
PORT_CAM_TARGET="$PORT_ROOTFS$CAM_DATA_DIR"
STOCK_CAM_SOURCE="$STOCK_ROOTFS$CAM_DATA_DIR"

echo -e "${CL_YEL}    [Mod: camera-fix] Harmonizing target camera feature parameters...${CL_RST}"

# Ensure camera configuration base layout directory exists in the port tree
sudo mkdir -p "$PORT_CAM_TARGET"

# -------------------------------------------------------------------------
# 1. Portrait Data Sync (Wipe donor's portrait models and replace with stock)
# -------------------------------------------------------------------------
if [ -d "$PORT_CAM_TARGET/portrait_data" ]; then
    echo "        [-] Removing donor portrait_data structures..."
    sudo rm -rf "$PORT_CAM_TARGET/portrait_data"
fi

if [ -d "$STOCK_CAM_SOURCE/portrait_data" ]; then
    echo "        [+] Restoring stock target portrait_data templates..."
    sudo cp -a "$STOCK_CAM_SOURCE/portrait_data" "$PORT_CAM_TARGET/"
fi

# -------------------------------------------------------------------------
# 2. Single Take Feature Profiles
# -------------------------------------------------------------------------
if [ -f "$STOCK_CAM_SOURCE/singletake/service-feature.xml" ]; then
    echo "        [*] Swapping with target stock single-take profiles..."
    sudo mkdir -p "$PORT_CAM_TARGET/singletake"
    sudo cp -a "$STOCK_CAM_SOURCE/singletake/service-feature.xml" "$PORT_CAM_TARGET/singletake/service-feature.xml"
fi

# -------------------------------------------------------------------------
# 3. AR Emoji Feature Profiles
# -------------------------------------------------------------------------
if [ -f "$STOCK_CAM_SOURCE/aremoji-feature.xml" ]; then
    echo "        [*] Swapping with target stock AR Emoji profiles..."
    sudo cp -a "$STOCK_CAM_SOURCE/aremoji-feature.xml" "$PORT_CAM_TARGET/aremoji-feature.xml"
fi

# -------------------------------------------------------------------------
# 4. Main Camera Feature Matrix (`camera-feature.xml`)
# -------------------------------------------------------------------------
if [ -f "$STOCK_CAM_SOURCE/camera-feature.xml" ]; then
    echo "        [*] Swapping with target stock master camera-feature matrix..."
    sudo cp -a "$STOCK_CAM_SOURCE/camera-feature.xml" "$PORT_CAM_TARGET/camera-feature.xml"
else
    echo -e "${CL_RED}        [-] Warning: Master camera-feature.xml could not be restored!${CL_RST}"
fi

# -------------------------------------------------------------------------
# 5. Metadata Permission & SELinux Context Synchronizer
# -------------------------------------------------------------------------
PORT_CFG="$PORT_META/unified_config-system"
STOCK_CFG="$STOCK_META/unified_config-system"

if [ -f "$STOCK_CFG" ] && [ -f "$PORT_CFG" ]; then
    echo "        [*] Aligning camera subsystem attributes and security mappings..."
    TMP_MOD_CFG=$(mktemp)
    
    # Extract file metadata context entries mapping specifically to /system/system/cameradata
    grep -E "^${CAM_DATA_DIR}" "$STOCK_CFG" > "$TMP_MOD_CFG"
    
    if [ -s "$TMP_MOD_CFG" ]; then
        TMP_MERGE=$(mktemp)
        cat "$PORT_CFG" "$TMP_MOD_CFG" > "$TMP_MERGE"
        
        # De-duplicate entries from the end using the kitchen's standard KISS parsing mechanic
        tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/unified_config-system"
        rm -f "$TMP_MERGE"
        echo -e "${CL_GRN}        [+] Camera file system metadata successfully bound.${CL_RST}"
    else
        rm -f "$TMP_MOD_CFG"
    fi
fi