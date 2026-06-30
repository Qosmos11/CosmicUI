#!/bin/bash
# scripts/check_deps.sh — Host Dependency Checker (Inherited Context)

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_CYN}[*] Checking host environment dependencies...${CL_RST}"

# Список критически важных утилит для работы кухни
REQUIRED_TOOLS=("fsck.erofs" "mkfs.erofs" "simg2img" "lpunpack" "python3" "setfattr" "getfattr")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

# Отдельная проверка для imgextractor или mount (должно быть хоть что-то одно)
if ! command -v imgextractor &> /dev/null; then
    echo -e "${CL_YEL}    [!] Warning: 'imgextractor' not found. Will use standard loop-mount fallback for ext4.${CL_RST}"
fi

# Если чего-то не хватает, кидаем структурированную ошибку
if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo -e "${CL_RED}[-] Error: Missing required system tools:${CL_RST}"
    for missing in "${MISSING_TOOLS[@]}"; do
        echo -e "    -> $missing"
    done
    echo -e "${CL_YEL}[*] Tip: Install dependencies via: your package manager erofs-utils android-sdk-libsparse-utils(android-tools for arch) attr xxd python3${CL_RST}"
    return 1
fi

echo -e "${CL_GRN}[+] All core host dependencies are satisfied!${CL_RST}"