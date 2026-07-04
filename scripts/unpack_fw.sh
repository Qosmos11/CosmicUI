#!/bin/bash

[ -d "$UNPACK_DIR" ] && [ "$(ls -A "$UNPACK_DIR" 2>/dev/null)" ] && { echo "Firmware is already here!"; return 0; }
[ ! -f "$FINAL_ZIP" ] && { echo  "There is no fw here..."; return 1; }

mkdir -p "$UNPACK_DIR"

if unzip -l "$FINAL_ZIP" | grep -q "AP_"; then
    unzip -p "$FINAL_ZIP" "AP_*" | tar -xC "$UNPACK_DIR" 2>/dev/null
else
    unzip -j -q "$FINAL_ZIP" "*" -d "$UNPACK_DIR" 2>/dev/null
fi

if ls "$UNPACK_DIR"/*.lz4 &>/dev/null; then
    echo "Decompressing all binaries..."
    for lz_file in "$UNPACK_DIR"/*.lz4; do
        [ -f "$lz_file" ] || continue
        lz4 -d -f --rm "$lz_file" "${lz_file%.lz4}" &>/dev/null
    done
fi

[ "$(ls -A "$UNPACK_DIR" 2>/dev/null)" ] && echo "All fw was unpacked!" || { echo "Something is wrong!"; return 1; }