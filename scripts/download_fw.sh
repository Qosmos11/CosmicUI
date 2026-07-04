#!/bin/bash
echo -e "Fetching $CURRENT_MODE Firmware ($MODEL)"

mkdir -p "$DOWNLOAD_DIR"

if [ -f "$FINAL_ZIP" ]; then
    echo "Firmware package already exists"
fi

SAM_CMD="-m $MODEL -r $REGION"

VERSION_TO_DOWNLOAD=""
if [ -n "$VERSION" ]; then
    echo "firmware version: $VERSION"
    VERSION_TO_DOWNLOAD="$VERSION"
else
    echo "Fetching firmware version."
    VERSION_TO_DOWNLOAD=$(samloader check-update $SAM_CMD)
    if [ -z "$VERSION_TO_DOWNLOAD" ]; then
        echo  "Failed to fetch."
        return 1
    fi
    echo "Latest version: $VERSION_TO_DOWNLOAD"
fi

# 5. Скачивание
echo "Starting download..."
samloader download $SAM_CMD -v "$VERSION_TO_DOWNLOAD" -o "$FINAL_ZIP"

# 7. Проверка результата
if [ -f "$FINAL_ZIP" ]; then
    echo "Firmware downloaded: $FINAL_ZIP"
else
    echo "Error: firmware.zip not found."
    return 1
fi