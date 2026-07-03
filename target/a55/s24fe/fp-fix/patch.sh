#!/bin/bash
# mods/edit_floating_features/patch.sh — Ultra-clean XML patcher

TARGET_XML_PATH="/system/system/etc/floating_feature.xml"
FILE_TO_PATCH="$PORT_ROOTFS$TARGET_XML_PATH"

echo -e "${CL_YEL}    [Mod: edit_floating_features] Patching features in floating_feature.xml...${CL_RST}"

if [ -f "$FILE_TO_PATCH" ]; then
    echo "        [*] Updating feature lines..."

    # =========================================================================
    # JUST WRITE YOUR LINES HERE
    # Syntax: TAG="FEATURE_NAME" VALUE="YOUR_VALUE"
    # =========================================================================

    TAG="SEC_FLOATING_FEATURE_LCD_CONFIG_LOCAL_HBM" VALUE="0"
    sudo sed -i "s|<\(${TAG}\)>[^<]*</\1>|<\1>${VALUE}</\1>|" "$FILE_TO_PATCH"

    # =========================================================================

    if [ $? -eq 0 ]; then
        echo -e "${CL_GRN}        [+] floating_feature.xml successfully patched.${CL_RST}"
    else
        echo -e "${CL_RED}        [-] Error: Failed to modify XML values.${CL_RST}"
    fi
else
    echo -e "${CL_RED}        [-] Error: Target floating_feature.xml not found in port tree!${CL_RST}"
fi