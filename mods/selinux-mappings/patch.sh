#!/bin/bash
# mods/swap_selinux_mapping/patch.sh — Swap system_ext SELinux mappings with target

TARGET_MAPPING_PATH="/system/system/system_ext/etc/selinux/mapping"
PORT_TARGET_DIR="$PORT_ROOTFS$TARGET_MAPPING_PATH"
STOCK_TARGET_DIR="$STOCK_ROOTFS$TARGET_MAPPING_PATH"
META_MAPPING_PATH="/system/system_ext/etc/selinux/mapping"

echo -e "${CL_YEL}    [Mod: swap_selinux_mapping] Swapping system_ext SELinux mappings...${CL_RST}"

# 1. Verify that the target (stock) mapping directory exists
if [ -d "$STOCK_TARGET_DIR" ]; then
    
    # Remove the donor mapping directory from the active port rootfs
    if [ -d "$PORT_TARGET_DIR" ]; then
        echo "        [-] Removing donor mapping files..."
        sudo rm -rf "$PORT_TARGET_DIR"
    fi
    
    # Copy target mapping directory into port rootfs
    echo "        [+] Copying target mapping files..."
    sudo cp -a "$STOCK_TARGET_DIR" "$PORT_TARGET_DIR"

    # 2. Sync metadata configurations so permissions/contexts are preserved
    # We look inside the stock metadata configuration for system_ext
    STOCK_CFG="$STOCK_META/unified_config-system"
    PORT_CFG="$PORT_META/unified_config-system"
    
    if [ -f "$STOCK_CFG" ] && [ -f "$PORT_CFG" ]; then
        echo "        [*] Syncing SELinux metadata records..."
        TMP_MOD_CFG=$(mktemp)
        
        # Extract metadata entries matching our swapped path from target stock config
        # We escape the path correctly to match lines starting with the directory path
        grep -E "^${META_MAPPING_PATH}" "$STOCK_CFG" > "$TMP_MOD_CFG"
        
        if [ -s "$TMP_MOD_CFG" ]; then
            TMP_MERGE=$(mktemp)
            
            # Combine current port config with our targeted stock overrides
            cat "$PORT_CFG" "$TMP_MOD_CFG" > "$TMP_MERGE"
            
            # Use your kiss deduplication logic to overwrite older metadata entries with target records
            tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/unified_config-system"
            
            rm -f "$TMP_MERGE"
            echo -e "${CL_GRN}        [+] SELinux mapping metadata successfully injected.${CL_RST}"
        else
            echo -e "${CL_RED}        [-] Warning: No metadata found for mapping folder in stock config.${CL_RST}"
        fi
        rm -f "$TMP_MOD_CFG"
    else
        echo -e "${CL_RED}        [-] Warning: Metadata configs missing. Permissions might be misaligned.${CL_RST}"
    fi

else
    echo -e "${CL_RED}        [-] Error: Target mapping directory not found in stock tree!${CL_RST}"
fi