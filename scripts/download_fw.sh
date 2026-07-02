#!/bin/bash
# scripts/download_fw.sh — Universal Firmware Downloader (Fixed Exit Scope)

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_CYN}>>> Module download_fw: Fetching $CURRENT_MODE Firmware ($MODEL)...${CL_RST}"

mkdir -p "$DOWNLOAD_DIR"

# 1. Проверка кэша
if [ -f "$FINAL_ZIP" ]; then
    echo -e "${CL_GRN}[+] Firmware package already exists in cache. Skipping download.${CL_RST}"
    return 0  # Использован return вместо exit
fi

# 3. Сборка команды
SAM_CMD="-m $MODEL -r $REGION"

# 4. Проверка версии
VERSION_TO_DOWNLOAD=""
if [ -n "$VERSION" ]; then
    echo "[+] Using specific firmware version from config: $VERSION"
    VERSION_TO_DOWNLOAD="$VERSION"
else
    echo "[!] No specific version provided. Fetching latest available build..."
    VERSION_TO_DOWNLOAD=$(samloader checkupdate $SAM_CMD)
    if [ -z "$VERSION_TO_DOWNLOAD" ]; then
        echo -e "${CL_RED}[-] Error: Failed to fetch version info.${CL_RST}"
        return 1
    fi
    echo "[+] Latest version found: $VERSION_TO_DOWNLOAD"
fi

# 5. Скачивание
echo "[+] Starting download..."
samloader download $SAM_CMD -v "$VERSION_TO_DOWNLOAD" -o "$FINAL_ZIP"

# 7. Проверка результата
if [ -f "$FINAL_ZIP" ]; then
    echo -e "${CL_GRN}[+] Firmware successfully downloaded: $FINAL_ZIP${CL_RST}"
else
    echo -e "${CL_RED}[-] Error: Output firmware.zip not found.${CL_RST}"
    return 1
fi