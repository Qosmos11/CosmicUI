#!/bin/bash

sudo rm -rf "$PORT_DIR"
mkdir -p "$PORT_ROOTFS" "$PORT_META"

echo "Copying donor fw."
sudo cp -a "$DONOR_ROOTFS"/. "$PORT_ROOTFS/"
sudo cp -a "$DONOR_META"/. "$PORT_META/"

if [ -d "$DONOR_UNPACK" ]; then
    find "$DONOR_UNPACK" -maxdepth 1 -type f -name "*.img" ! -name "super.img" ! -name "super.img.raw" -exec cp {} "$PORT_DIR/" \; 2>/dev/null
fi

MODS_LIST=( "${BASE_MODS[@]}" "${TARGET_MODS[@]}"

for mod_path in "${MODS_LIST[@]}"; 
    mod_dir="./mods/$mod_path"
    if [ -d "$mod_dir" ]; then
        for custom_cfg in "$mod_dir"/unified_config-*; do
             if [ -f "$custom_cfg" ]; then
                cfg_target=$(basename "$custom_cfg")          
                TMP_MERGE=$(mktemp)
                cat "$PORT_META/$cfg_target" "$custom_cfg" 2>/dev/null > "$TMP_MERGE"
                tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/$cfg_target"
                rm -f "$TMP_MERGE"
             fi
        done
        if [ -f "$mod_dir/patch.sh" ]; then
            echo "Applying module: $mod_sub_name"
            STOCK_META_DIR="$STOCK_META"
            source "$mod_dir/patch.sh"
        fi

echo "All mods are done!"