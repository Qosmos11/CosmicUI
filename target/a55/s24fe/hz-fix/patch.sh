#!/bin/bash
# target/a55/s24fe/hz-fix/patch.sh — Force 120Hz compositor properties on S24FE base

TARGET_PROP_PATH="/system/system/build.prop"
FILE_TO_PATCH="$PORT_ROOTFS$TARGET_PROP_PATH"

echo -e "${CL_YEL}    [Mod: hz-fix] Injecting 120Hz refresh overrides into build.prop...${CL_RST}"

if [ -f "$FILE_TO_PATCH" ]; then
    echo "        [*] Appending SurfaceFlinger performance overrides..."

    # Injecting the properties directly into the system build configuration
    sudo tee -a "$FILE_TO_PATCH" > /dev/null << 'EOF'

# =========================================================================
# Custom Mod: 60Hz Animation Drop Fix (S24FE Base on A55 Target)
# =========================================================================
ro.surface_flinger.set_touch_timer_ms=0
ro.surface_flinger.set_idle_timer_ms=0
debug.sf.disable_hwc_vds=1
debug.sf.latch_unsignaled=1
ro.vendor.display.default_fps=120
# =========================================================================
EOF

    if [ $? -eq 0 ]; then
        echo -e "${CL_GRN}        [+] build.prop successfully patched with 120Hz force overrides.${CL_RST}"
    else
        echo -e "${CL_RED}        [-] Error: Failed to append values to build.prop.${CL_RST}"
    fi
else
    echo -e "${CL_RED}        [-] Error: Target build.prop not found in port tree!${CL_RST}"
fi