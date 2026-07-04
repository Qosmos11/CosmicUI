#!/bin/bash

sudo rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

PARTITIONS=($(find "$PORT_ROOTFS" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null))

for part in "${PARTITIONS[@]}"; do
    SRC_SUBDIR="$PORT_ROOTFS/$part"
    IMG_OUTPUT="$OUTPUT_DIR/$part.img"
    UNIFIED_CONFIG="$PORT_META/unified_config-$part"
    
    if [ ! -f "$UNIFIED_CONFIG" ]; then
        continue
    fi

    echo "Processing partition: [$part]"
    rm -f "$IMG_OUTPUT"
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

    echo "Building image..."
    sudo mkfs.erofs \
        -z lz4hc,9 \
        -b 4096 \
        -T 1640995200 \
        --mount-point="/$part" \
        "$IMG_OUTPUT" "$SRC_SUBDIR/" &> /dev/null
        
    if [ -f "$IMG_OUTPUT" ] && [ -s "$IMG_OUTPUT" ]; then
        echo "Done!"
    else
        echo "Error!"
    fi
done

find "$PORT_DIR" -maxdepth 1 -type f -name "*.img" -exec cp {} "$OUTPUT_DIR/" \; 2>/dev/null

echo "All img are repacked"