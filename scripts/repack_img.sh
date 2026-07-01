#!/bin/bash
# scripts/repack_img.sh — Native Metadata Stamper & EROFS Packer

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_YEL}>>> Module repack_img: Stamping Production Metadata & Packing EROFS...${CL_RST}"

mkdir -p "$OUTPUT_DIR"

PARTITIONS=($(find "$PORT_ROOTFS" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null))

for part in "${PARTITIONS[@]}"; do
    SRC_SUBDIR="$PORT_ROOTFS/$part"
    IMG_OUTPUT="$OUTPUT_DIR/$part.img"
    UNIFIED_CONFIG="$PORT_META/unified_config-$part"
    
    if [ ! -f "$UNIFIED_CONFIG" ]; then
        continue
    fi

    echo -e "${CL_CYN}[*] Processing partition: [$part]...${CL_RST}"
    rm -f "$IMG_OUTPUT"

    echo "    -> Applying secure metadata layer directly to files..."
    while IFS="|" read -r r_path uid gid mode selinux_ctx capabilities; do
        [ -z "$r_path" ] && continue
        
        if [ "$r_path" = "/" ]; then
            local_path="$SRC_SUBDIR"
        else
            local_path="$SRC_SUBDIR$r_path"
        fi
        
        if [ -e "$local_path" ] || [ -L "$local_path" ]; then
            sudo chown -h "$uid:$gid" "$local_path"
            sudo chmod -h "$mode" "$local_path" 2>/dev/null
            
            if [ -L "$local_path" ]; then
                sudo chmod -f "$mode" "$local_path" 2>/dev/null
            fi
            
            sudo setfattr -hn security.selinux -v "${selinux_ctx}\0" "$local_path" 2>/dev/null
            
            if [ "$capabilities" != "0x0" ] && [ "$capabilities" != "0x00000000" ]; then
                cap_bin=$(echo "${capabilities}" | sed 's|^0x||')
                
                echo "$cap_bin" | xxd -r -p | sudo setfattr -hn security.capability -v - "$local_path" 2>/dev/null
            fi
        fi
    done < "$UNIFIED_CONFIG"

    echo "    -> Compressing and baking final EROFS image via LZ4HC..."
    sudo mkfs.erofs \
        -z lz4hc,9 \
        -b 4096 \
        -T 1640995200 \
        --mount-point="/$part" \
        "$IMG_OUTPUT" "$SRC_SUBDIR/" &> /dev/null
        
    if [ -f "$IMG_OUTPUT" ] && [ -s "$IMG_OUTPUT" ]; then
        echo -e "${CL_GRN}    [+] Done! Baked: $IMG_OUTPUT ($(du -sh "$IMG_OUTPUT" | awk '{print $1}'))${CL_RST}"
    else
        echo -e "${CL_RED}    [-] Error: Packaging failed for $part.${CL_RST}"
    fi
done

echo -e "${CL_CYN}[*] Mirroring companion standalone images to output folder...${CL_RST}"
find "$PORT_DIR" -maxdepth 1 -type f -name "*.img" -exec cp {} "$OUTPUT_DIR/" \; 2>/dev/null

echo -e ""
echo -e "${CL_GRN}[+] ALL HYBRID IMAGES SUCCESSFULLY COMPRESSED! Check: $OUTPUT_DIR${CL_RST}"