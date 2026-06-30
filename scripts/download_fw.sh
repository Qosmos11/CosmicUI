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

if [ -f "$NO_EXT_FILE" ]; then
    echo "[+] Found decrypted base without extension. Converting to firmware.zip..."
    mv "$NO_EXT_FILE" "$FINAL_ZIP"
    echo -e "${CL_GRN}[+] Firmware successfully prepared: $FINAL_ZIP${CL_RST}"
    return 0  # Использован return вместо exit
fi

# 2. Проверка samloader
if ! command -v samloader &> /dev/null; then
    echo "[!] samloader CLI not found. Installing via pip..."
    pip3 install git+https://github.com/ananjaser1211/samloader.git --upgrade &> /dev/null
fi

# 3. Сборка команды
SAM_CMD="samloader -m $MODEL -r $REGION"
if [ -n "$IMEI" ]; then
    SAM_CMD="$SAM_CMD -i $IMEI"
fi

# 4. Проверка версии
VERSION_TO_DOWNLOAD=""
if [ -n "$VERSION" ]; then
    echo "[+] Using specific firmware version from config: $VERSION"
    VERSION_TO_DOWNLOAD="$VERSION"
else
    echo "[!] No specific version provided. Fetching latest available build..."
    VERSION_TO_DOWNLOAD=$($SAM_CMD checkupdate)
    if [ -z "$VERSION_TO_DOWNLOAD" ]; then
        echo -e "${CL_RED}[-] Error: Failed to fetch version info.${CL_RST}"
        return 1
    fi
    echo "[+] Latest version found: $VERSION_TO_DOWNLOAD"
fi

# 5. Скачивание
echo "[+] Starting download..."
$SAM_CMD download -v "$VERSION_TO_DOWNLOAD" -o "$TMP_ENC_FILE"

# 6. Расшифровка
if [ -f "$TMP_ENC_FILE" ]; then
    echo "[+] Decrypting firmware package on-the-fly..."
    $SAM_CMD decrypt -v "$VERSION_TO_DOWNLOAD" -i "$TMP_ENC_FILE" -o "$FINAL_ZIP"
    rm -f "$TMP_ENC_FILE"
fi

if [ -f "$NO_EXT_FILE" ] && [ ! -f "$FINAL_ZIP" ]; then
    mv "$NO_EXT_FILE" "$FINAL_ZIP"
fi

# 7. Проверка результата
if [ -f "$FINAL_ZIP" ]; then
    echo -e "${CL_GRN}[+] Firmware successfully downloaded and decrypted: $FINAL_ZIP${CL_RST}"
else
    echo -e "${CL_RED}[-] Error: Output firmware.zip not found.${CL_RST}"
    return 1
fi