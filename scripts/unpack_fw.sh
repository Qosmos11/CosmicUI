#!/bin/bash
# scripts/unpack_fw.sh — Nuclear Unix-Way Total Firmware Unpacker

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_CYN}>>> Module unpack_fw: Extracting ABSOLUTELY ALL Components ($CURRENT_MODE)...${CL_RST}"

# Если папка существует и в ней уже есть файлы — скипаем
[ -d "$UNPACK_DIR" ] && [ "$(ls -A "$UNPACK_DIR" 2>/dev/null)" ] && { echo -e "${CL_GRN}    [+] Firmware components already exist. Skipping.${CL_RST}"; return 0; }
[ ! -f "$FINAL_ZIP" ] && { echo -e "${CL_RED}[-] Error: Missing $FINAL_ZIP${CL_RST}"; return 1; }

mkdir -p "$UNPACK_DIR"

if unzip -l "$FINAL_ZIP" | grep -q "AP_"; then
    echo "    -> Samsung AP Tarball pipeline activated (Extracting complete firmware tree)..."
    # Распаковываем AP_*.tar полностью без фильтров прямо в целевую папку
    unzip -p "$FINAL_ZIP" "AP_*" | tar -xC "$UNPACK_DIR" 2>/dev/null
else
    echo "    -> Standard ZIP pipeline activated (Extracting everything)..."
    # Для обычных ZIP — просто вываливаем всё содержимое корня архива
    unzip -j -q "$FINAL_ZIP" "*" -d "$UNPACK_DIR" 2>/dev/null
fi

# Тотальный декомпрессор для всех файлов, у которых имя заканчивается на .lz4
if ls "$UNPACK_DIR"/*.lz4 &>/dev/null; then
    echo "[+] Decompressing all LZ4 binaries..."
    for lz_file in "$UNPACK_DIR"/*.lz4; do
        [ -f "$lz_file" ] || continue
        lz4 -d -f --rm "$lz_file" "${lz_file%.lz4}" &>/dev/null
    done
fi

# Финальная проверка по факту наличия любых файлов в папке
[ "$(ls -A "$UNPACK_DIR" 2>/dev/null)" ] && echo -e "${CL_GRN}[+] Entire firmware package successfully staged.${CL_RST}" || { echo -e "${CL_RED}[-] Error: Extraction failed.${CL_RST}"; return 1; }