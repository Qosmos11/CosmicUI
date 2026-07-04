#!/bash/bin

if [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
    echo  "Rootfs is already here."
    return 0
fi

if [ ! -f "$EXTRACT_DIR/system.img" ] || [ ! -f "$EXTRACT_DIR/vendor.img" ]; then
    if [ ! -f "$SUPER_IMG" ]; then
        echo "Get super.img when?"
        return 1
    fi

    mkdir -p "$EXTRACT_DIR"
    simg2img "$SUPER_IMG" "$RAW_SUPER_IMG"

    if [ ! -s "$RAW_SUPER_IMG" ]; then
        echo "Converting failed!"
        rm -rf "$RAW_SUPER_IMG"
        return 1
    fi

    echo "Lpunpacking..."
    lpunpack "$RAW_SUPER_IMG" "$EXTRACT_DIR"
    rm -f "$RAW_SUPER_IMG"
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

AVAILABLE_IMAGES=($(find "$EXTRACT_DIR" -maxdepth 1 -type f -name "*.img" | sort 2>/dev/null))

if [ ${#AVAILABLE_IMAGES[@]} -eq 0 ]; then
    echo "There is no .img files."
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
    
    echo "Unpacking $img_name..."  
    sudo fsck.erofs --extract="$TARGET_OUT_DIR" --xattrs --force --overwrite --preserve "$IMG_FILE" &>/dev/null 
    if [ -z "$(ls -A "$TARGET_OUT_DIR" 2>/dev/null)" ]; then
        echo "Failed to unpack $img_name"
        sudo rm -rf "$TARGET_OUT_DIR"
        continue
    fi

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
    echo "Partition $img_name mapped successfully."
done