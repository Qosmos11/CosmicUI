#!/bin/bash
# scripts/check_deps.sh — Host Dependency Checker (Inherited Context)

[ -z "$TARGET" ] && { echo -e "${CL_RED}[-] Error: Run via build.sh${CL_RST}"; return 1; }

echo -e "${CL_CYN}[*] Checking host environment dependencies...${CL_RST}"
#!/bin/bash


if   command -v apt-get &>/dev/null; then PKG_MAN="sudo apt-get install -y"
elif command -v dnf     &>/dev/null; then PKG_MAN="sudo dnf install -y"
elif command -v pacman  &>/dev/null; then PKG_MAN="sudo pacman -S --noconfirm"
elif command -v zypper  &>/dev/null; then PKG_MAN="sudo zypper install -y"
elif command -v yum     &>/dev/null; then PKG_MAN="sudo yum install -y"
else echo "Unsupported OS"; exit 1; fi

if ! command -v lz4 &> /dev/null; then
    $PKG_MAN lz4
fi

if ! command -v wget &> /dev/null; then
    $PKG_MAN wget
fi

if command -v samloader &> /dev/null; then
    echo -e "${CL_RED}Make sure you are running samloader-rs${CL_RST}"
fi

if ! command -v samloader &> /dev/null; then
    wget https://github.com/topjohnwu/samloader-rs/releases/download/2.0.0/samloader-v2.0.0-linux-x86_64.tar.xz
    tar -xf samloader-v2.0.0-linux-x86_64.tar.xz
    sudo mv samloader /usr/local/bin/
    rm -rf samloader-v2.0.0-linux-x86_64.tar.xz
fi

if ! command -v unzip &> /dev/null; then
    $PKG_MAN unzip
fi

if ! command -v simg2img &> /dev/null; then
    echo -e "${CL_RED}[-] Install android-tools(arch) or other package with simg2img${CL_RST}"
    return 1
fi

if ! command -v lpunpack &> /dev/null; then
    echo -e "${CL_RED}[-] Install android-tools(arch) or other package with simg2img${CL_RST}"
    return 1
fi

if ! command -v fsck.erofs &> /dev/null; then
    $PKG_MAN erofs-utils
fi

if ! command -v xxd &> /dev/null; then
    $PKG_MAN xxd
fi

echo -e "${CL_GRN}[+] All core host dependencies are satisfied!${CL_RST}"