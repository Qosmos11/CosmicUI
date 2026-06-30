#!/bin/bash
# scripts/patch_port.sh — Pure Layered Overlap Engine

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_YEL}>>> Module patch_port: Staging and Orchestrating Targeted Patches...${CL_RST}"

echo "[*] Cleaning up and staging fresh port directories..."
sudo rm -rf "$PORT_DIR"
mkdir -p "$PORT_ROOTFS" "$PORT_META"

echo "[*] Staging pure Donor files ($BASE) into Port tree..."
sudo cp -a "$DONOR_ROOTFS"/. "$PORT_ROOTFS/"
sudo cp -a "$DONOR_META"/. "$PORT_META/"

echo "[*] Staging standalone images (vbmeta, boot, recovery, etc.) into Port tree..."
if [ -d "$DONOR_UNPACK" ]; then
    find "$DONOR_UNPACK" -maxdepth 1 -type f -name "*.img" ! -name "super.img" ! -name "super.img.raw" -exec cp {} "$PORT_DIR/" \; 2>/dev/null
fi

echo "[*] Applying layer: Global Modifications..."
if [ -d "./mods" ]; then
    for mod_dir in ./mods/*; do
        [ -d "$mod_dir" ] || continue
        mod_name=$(basename "$mod_dir")
        
        for custom_cfg in "$mod_dir"/unified_config-*; do
            if [ -f "$custom_cfg" ]; then
                cfg_target=$(basename "$custom_cfg")
                echo -e "    [Config] Injecting custom entries from $mod_name/$cfg_target..."
                
                TMP_MERGE=$(mktemp)
                cat "$PORT_META/$cfg_target" "$custom_cfg" 2>/dev/null > "$TMP_MERGE"
                
                tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/$cfg_target"
                rm -f "$TMP_MERGE"
            fi
        done

        if [ -d "$mod_dir/images" ]; then
            echo -e "    -> Injecting custom module images from $mod_name..."
            cp -rf "$mod_dir/images"/*.img "$PORT_DIR/" 2>/dev/null
        fi

        if [ -f "$mod_dir/patch.sh" ]; then
            echo -e "    -> Executing module script: $mod_name"
            STOCK_META_DIR="$STOCK_META"
            source "$mod_dir/patch.sh"
        fi
    done
fi

echo -e "${CL_GRN}[+] STAGE 5 COMPLETE. Hybrid layered tree fully prepared!${CL_RST}"