#!/bin/bash

TARGET=$1
BASE=$2

source "./config.sh"
source "./scripts/check_deps.sh"

source "./target/$TARGET/$BASE.sh"
CURRENT_MODE="$BASE"
source "./config.sh"
source "./scripts/download_fw.sh"
source "./scripts/unpack_fw.sh"
source "./scripts/unpack_img.sh"

source "./target/$TARGET/config.sh"
CURRENT_MODE="$TARGET"
source "./config.sh"
source "./scripts/download_fw.sh"
source "./scripts/unpack_fw.sh"
source "./scripts/unpack_img.sh"


source "./config.sh"
source "./scripts/patch_port.sh"
source "./scripts/repack_img.sh"

echo "Done!"