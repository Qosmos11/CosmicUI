#!/bin/bash
TARGET_MAPPING_PATH="/system/system/system_ext/etc/selinux/mapping"
PORT_TARGET_DIR="$PORT_ROOTFS$TARGET_MAPPING_PATH"
STOCK_TARGET_DIR="$STOCK_ROOTFS$TARGET_MAPPING_PATH"
META_MAPPING_PATH="/system/system_ext/etc/selinux/mapping"

if [ -d "$STOCK_TARGET_DIR" ]; then
    if [ -d "$PORT_TARGET_DIR" ]; then
        echo "Removing donor mapping files."
        sudo rm -rf "$PORT_TARGET_DIR"
    fi
    echo "Copying target mapping files."
    sudo cp -a "$STOCK_TARGET_DIR" "$PORT_TARGET_DIR"
    
    STOCK_CFG="$STOCK_META/unified_config-system"
    PORT_CFG="$PORT_META/unified_config-system"
    
    if [ -f "$STOCK_CFG" ] && [ -f "$PORT_CFG" ]; then
        echo "Syncing SELinux"
        TMP_MOD_CFG=$(mktemp)
        grep -E "^${META_MAPPING_PATH}" "$STOCK_CFG" > "$TMP_MOD_CFG"
        
        if [ -s "$TMP_MOD_CFG" ]; then
            TMP_MERGE=$(mktemp)
            cat "$PORT_CFG" "$TMP_MOD_CFG" > "$TMP_MERGE"
            tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/unified_config-system"
            
            rm -f "$TMP_MERGE"
        else
            echo "No metadata found for mapping"
        fi
        rm -f "$TMP_MOD_CFG"
    else
        echo "Metadata is missing."
    fi

else
    echo "Target mapping directory not found"
fi