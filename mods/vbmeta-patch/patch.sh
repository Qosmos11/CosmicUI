#!/bin/bash
# target/a55/common/disable_avb/patch.sh — Un1ca VBMETA Patcher with Cleanup

ORIG_VBMETA="$PORT_DIR/vbmeta.img"
PATCHED_VBMETA="$PORT_DIR/vbmeta_patched.img"

echo -e "${CL_YEL}    [Mod: disable_avb] Creating and patching vbmeta_patched.img...${CL_RST}"

if [ -f "$ORIG_VBMETA" ]; then
    # Шаг 1: Копируем оригинал в патченную версию
    cp -a "$ORIG_VBMETA" "$PATCHED_VBMETA"
    
    # Шаг 2: Вносим изменения через dd в новый файл
    # Смещение 123, пишем байт 0x03 (отключает verity и verification)
    printf "\x03" | dd of="$PATCHED_VBMETA" bs=1 seek=123 count=1 conv=notrunc &>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${CL_GRN}        [+] vbmeta_patched.img successfully created and patched.${CL_RST}"
        # Шаг 3: Удаляем оригинальную стоковую vbmeta.img
        rm -f "$ORIG_VBMETA"
        echo "        [-] Original vbmeta.img removed from port tree."
    else
        echo -e "${CL_RED}        [-] Error: Failed to patch vbmeta_patched.img!${CL_RST}"
        rm -f "$PATCHED_VBMETA"
    fi
else
    echo -e "${CL_RED}        [-] Error: Source vbmeta.img not found in port tree!${CL_RST}"
fi