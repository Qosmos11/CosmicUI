#!/bin/bash

TARGET_XML_PATH="/system/system/etc/floating_feature.xml"
FILE_TO_PATCH="$PORT_ROOTFS$TARGET_XML_PATH"

if [ -f "$FILE_TO_PATCH" ]; then
    echo "Patching."

    TAG="SEC_FLOATING_FEATURE_LCD_CONFIG_LOCAL_HBM" VALUE="0"
    sudo sed -i "s|<\(${TAG}\)>[^<]*</\1>|<\1>${VALUE}</\1>|" "$FILE_TO_PATCH"

    # =========================================================================

    if [ $? -eq 0 ]; then
        echo "Successfully patched."
    else
        echo "Error!"
    fi
else
    echo "floating_feature.xml not found"
fi