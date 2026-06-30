#!/bin/bash
# mods/03_replace_wallpaper_res/patch.sh

echo "[*] Mod: Replacing existing wallpaper-res.apk..."

# Путь к файлу внутри рабочего дерева порта
TARGET_FILE="$PORT_ROOTFS/system/system/priv-app/wallpaper-res/wallpaper-res.apk"

# Проверяем, есть ли вообще оригинал, который мы хотим заменить
if [ -f "$TARGET_FILE" ]; then
    # Копируем поверх
    sudo cp -f "$(dirname "$BASH_SOURCE")/wallpaper-res.apk" "$TARGET_FILE"
    echo "[+] wallpaper-res.apk successfully replaced."
else
    echo "[-] Warning: Original wallpaper-res.apk not found in donor tree! Creating new path..."
    sudo mkdir -p "$(dirname "$TARGET_FILE")"
    sudo cp -f "$(dirname "$BASH_SOURCE")/wallpaper-res.apk" "$TARGET_FILE"
fi