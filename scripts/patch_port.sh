#!/bin/bash
# scripts/patch_port.sh — Pure Layered Overlap Engine (Hierarchical Edition)

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

# ====================================================
# ФУНКЦИЯ НАКАТА СЛОЯ МОДОВ (Unix-Way Reusable Block)
# ====================================================
apply_mod_layer() {
    local layer_path="$1"
    local layer_name="$2"

    if [ -d "$layer_path" ]; then
        echo -e "${CL_CYN}[*] Applying layer: $layer_name ($layer_path)...${CL_RST}"
        
        for mod_dir in "$layer_path"/*; do
            [ -d "$mod_dir" ] || continue
            mod_sub_name=$(basename "$mod_dir")
            
            # 1. Объединение конфигураций метаданных и прав (UID/GID/SELinux)
            for custom_cfg in "$mod_dir"/unified_config-*; do
                if [ -f "$custom_cfg" ]; then
                    cfg_target=$(basename "$custom_cfg")
                    echo -e "    [Config] Injecting entries from $mod_sub_name/$cfg_target..."
                    
                    TMP_MERGE=$(mktemp)
                    cat "$PORT_META/$cfg_target" "$custom_cfg" 2>/dev/null > "$TMP_MERGE"
                    
                    # Перезаписываем старые строки новыми (KISS дедупликация с конца)
                    tac "$TMP_MERGE" | awk -F'|' '!x[$1]++' | tac > "$PORT_META/$cfg_target"
                    rm -f "$TMP_MERGE"
                fi
            done

            # 3. Запуск кастомных bash-скриптов патчинга внутри мода
            if [ -f "$mod_dir/patch.sh" ]; then
                echo -e "    -> Executing module script: $mod_sub_name"
                STOCK_META_DIR="$STOCK_META"
                source "$mod_dir/patch.sh"
            fi
        done
    fi
}

# ====================================================
# ЗАПУСК ИЕРАРХИИ СЛОЕВ (От общего к частному)
# ====================================================

# Слой 1: Глобальные моды для всех устройств (корень кухни)
apply_mod_layer "./mods" "Global Kitchen Mods"

# Слой 2: Общие моды конкретно для твоего девайса (a55)
apply_mod_layer "./target/$TARGET/common" "Device Specific Common Mods"

# Слой 3: Самые точечные патчи для связки (a55 + s24fe в качестве базы)
apply_mod_layer "./target/$TARGET/$BASE" "Hybrid Hybrid-Pair Specific Fixes"

# ====================================================

echo -e "${CL_GRN}[+] STAGE 5 COMPLETE. Hierarchical layered tree fully prepared!${CL_RST}"