#!/bash/bin
# scripts/unpack_all.sh — Unified Block Extractor & Rootfs Mapper

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_CYN}>>> Module unpack_all: Staging Dynamic Block Infrastructure ($CURRENT_MODE)...${CL_RST}"

# ====================================================
# СУПЕР-КОМПАКТНЫЙ СКИП-ЧЕК (ЕСЛИ ROOTFS УЖЕ ГОТОВА)
# ====================================================
if [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
    echo -e "${CL_GRN}[+] Rootfs directories for $CURRENT_MODE already exist. Global Skip!${CL_RST}"
    return 0
fi

# ====================================================
# ШАГ 1: РАЗБОРОЧНЫЙ ЦЕХ ДЛЯ SUPER.IMG (Бывший unpack_super)
# ====================================================
if [ ! -f "$EXTRACT_DIR/system.img" ] || [ ! -f "$EXTRACT_DIR/vendor.img" ]; then
    if [ ! -f "$SUPER_IMG" ]; then
        echo -e "${CL_RED}[-] Error: super.img not found for $CURRENT_MODE!${CL_RST}"
        return 1
    fi

    mkdir -p "$EXTRACT_DIR"

    echo "[+] Converting sparse super.img to raw layout..."
    simg2img "$SUPER_IMG" "$RAW_SUPER_IMG"

    if [ ! -s "$RAW_SUPER_IMG" ]; then
        echo -e "${CL_RED}[-] Error: Conversion failed.${CL_RST}"
        rm -rf "$RAW_SUPER_IMG"
        return 1
    fi

    echo "[+] Running lpunpack on unsparsed $RAW_SUPER_IMG..."
    lpunpack "$RAW_SUPER_IMG" "$EXTRACT_DIR"
    rm -f "$RAW_SUPER_IMG"

    echo "[+] Normalizing A/B partition structure..."
    cd "$EXTRACT_DIR" || return 1
    rm -f *_b.img

    for slot_file in *_a.img; do
        if [ -f "$slot_file" ]; then
            clean_name="${slot_file%_a.img}.img"
            mv "$slot_file" "$clean_name"
        fi
    done
    cd - > /dev/null || return 1
fi

# ====================================================
# ШАГ 2: РАСПАКОВКА ФАЙЛОВОЙ СИСТЕМЫ И ПРАВ (Бывший unpack_img)
# ====================================================
AVAILABLE_IMAGES=($(find "$EXTRACT_DIR" -maxdepth 1 -type f -name "*.img" | sort 2>/dev/null))

if [ ${#AVAILABLE_IMAGES[@]} -eq 0 ]; then
    echo -e "${CL_RED}[-] Error: No unpacked images found in $EXTRACT_DIR!${CL_RST}"
    return 1
fi

mkdir -p "$ROOTFS_DIR" "$METADATA_DIR"

for IMG_FILE in "${AVAILABLE_IMAGES[@]}"; do
    img_name=$(basename "$IMG_FILE" | sed 's|\.img$||')
    TARGET_OUT_DIR="$ROOTFS_DIR/$img_name"

    sudo rm -rf "$TARGET_OUT_DIR"
    mkdir -p "$TARGET_OUT_DIR"
    
    UNIFIED_CONFIG="$METADATA_DIR/unified_config-$img_name"
    > "$UNIFIED_CONFIG"
    
    echo "[*] Unpacking EROFS partition: $img_name..."  
    sudo fsck.erofs --extract="$TARGET_OUT_DIR" --xattrs --force --overwrite --preserve "$IMG_FILE" &>/dev/null 
    if [ -z "$(ls -A "$TARGET_OUT_DIR" 2>/dev/null)" ]; then
        echo -e "${CL_RED}    [-] Failed to unpack $img_name. Skipping permission mapping.${CL_RST}"
        sudo rm -rf "$TARGET_OUT_DIR"
        continue
    fi
    
    echo "    -> Gathering attributes for $img_name..."
    FLIST=$(mktemp)
    sudo find "$TARGET_OUT_DIR" > "$FLIST"
    
    while read -r f_path; do
        [ -z "$f_path" ] && continue
        
        read -r uid gid mode <<< "$(sudo stat -c "%u %g %a" "$f_path")"
        
        cap_raw=$(sudo getfattr -n security.capability --only-values -h --absolute-names "$f_path" 2>/dev/null | od -An -v -tx1 | tr -d ' \n')
        [ -z "$cap_raw" ] && cap_raw="0x0" || cap_raw="0x$cap_raw"
        
        selinux_ctx=$(sudo getfattr -n security.selinux --only-values -h --absolute-names "$f_path" 2>/dev/null | tr -d '\0')
        [ -z "$selinux_ctx" ] && selinux_ctx="u:object_r:unlabeled:s0"
        
        r_path=$(echo "$f_path" | sed "s|^$TARGET_OUT_DIR||")
        [ -z "$r_path" ] && r_path="/"
        
        if [ "$r_path" = "/" ]; then
            echo "/|$uid|$gid|$mode|$selinux_ctx|$cap_raw" >> "$UNIFIED_CONFIG"
        else
            echo "$r_path|$uid|$gid|$mode|$selinux_ctx|$cap_raw" >> "$UNIFIED_CONFIG"
        fi
    done < "$FLIST"
    rm -f "$FLIST"
    echo -e "${CL_GRN}[+] Partition $img_name mapped successfully.${CL_RST}"
done