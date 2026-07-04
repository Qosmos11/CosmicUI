#!/bin/bash

sudo rm -rf "$PORT_DIR"
mkdir -p "$PORT_ROOTFS" "$PORT_META"

echo "Copying donor fw."
sudo cp -a "$DONOR_ROOTFS"/. "$PORT_ROOTFS/"
sudo cp -a "$DONOR_META"/. "$PORT_META/"

if [ -d "$DONOR_UNPACK" ]; then
    find "$DONOR_UNPACK" -maxdepth 1 -type f -name "*.img" ! -name "super.img" ! -name "super.img.raw" -exec cp {} "$PORT_DIR/" \; 2>/dev/null
fi

apply_mod_layer() {
    local layer_path="$1"
    local layer_name="$2"

    if [ -d "$layer_path" ]; then        
        for mod_dir in "$layer_path"/*; do
            [ -d "$mod_dir" ] || continue
            mod_sub_name=$(basename "$mod_dir")
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
        done
    fi
}

apply_mod_layer "./source/$BASE/patches" "Source Specific Mods"

apply_mod_layer "./mods" "Global Kitchen Mods"

apply_mod_layer "./target/$TARGET/common" "Device Specific Common Mods"

apply_mod_layer "./target/$TARGET/$BASE" "Hybrid Hybrid-Pair Specific Fixes"


echo "All mods are done!"