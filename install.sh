#!/bin/bash

set -euo pipefail

DAHDI_DKMS="allstar-dahdi-linux-dkms_3.4.0.20250220-1_all.deb"
DAHDI_TOOLS="allstar-dahdi-linux-tools_3.4.0.20250220-1_amd64.deb"
N_DAHDI_DKMS="allstar-dahdi-linux-dkms"
N_DAHDI_TOOLS="allstar-dahdi-linux-tools"
ASL_DEB=""

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo." >&2
        exit 1
    fi
}

confirm_installation() {
    echo "NOTE: This script will remove any existing installation of DAHDI and ALLSTARLINK"
    read -p "Are you sure you want to proceed? (Y/N): " response
    case "$response" in
        [Yy]) echo "Proceeding with the installation." ;;
        [Nn]) echo "Installation canceled."; exit 1 ;;
        *) echo "Invalid input. Please enter Y or N."; confirm_installation ;;
    esac
}

detect_debian_version() {
    if command -v lsb_release &> /dev/null; then
        DEBIAN_VERSION=$(lsb_release -sr | cut -d. -f1)
    elif [ -f /etc/os-release ]; then
        DEBIAN_VERSION=$(grep "VERSION_ID" /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        echo "Unable to detect Debian version. Exiting." >&2
        exit 1
    fi
    echo "Detected Debian version: $DEBIAN_VERSION"
}

determine_packages() {
    case "$DEBIAN_VERSION" in
        10|11)
            LIBCOMERR_PACKAGE="libcomerr2"
            LIBGCC1_PACKAGE="libgcc1"
            LIBIDN_PACKAGE="libidn11"
            ASL_DEB="allstar-asteriskX-full_1.02X-20250227-2_debian11_amd64.deb"
            ;;
        12|13)
            LIBCOMERR_PACKAGE="libcom-err2"
            LIBGCC1_PACKAGE="libgcc-s1"
            LIBIDN_PACKAGE="libidn12"
            ASL_DEB="allstar-asteriskX-full_1.02X-20250227-2_debian12_amd64.deb"
            ;;
        *)
            echo "Unsupported Debian version. Exiting."
            exit 1
            ;;
    esac
}

update_system() {
    apt update && apt upgrade -y
}

install_dependencies() {
    apt install -y dkms fxload libasound2 libc6 \
        $LIBCOMERR_PACKAGE libcurl4 $LIBGCC1_PACKAGE libgsm1 \
        $LIBIDN_PACKAGE libiksemel3 libncurses5 libnewt0.52 libogg0 \
        libpopt0 libpri1.4 libspeex1 libstdc++6 libtonezone-dev \
        libusb-0.1-4 libusb-1.0-0 libvorbis0a libvorbisenc2 libwrap0 \
        linux-headers-$(uname -r) perl procps python3-iniparse usbutils wget zlib1g
}

download_deb_files() {
    for file in "$DAHDI_DKMS" "$DAHDI_TOOLS" "$ASL_DEB"; do
        echo "Downloading $file..."
        wget -q "https://raw.githubusercontent.com/DU8BL/Allstar-AsteriskX-Full/main/$file" || {
            echo "Error: Failed to download $file."
            exit 1
        }
    done
}

check_installed_version() {
    local deb_version
    deb_version=$(echo "$ASL_DEB" | awk -F'_' '{print $2}')

    local installed_version
    installed_version=$(dpkg-query -W -f='${Version}\n' allstar-asteriskx-full 2>/dev/null || echo "not installed")

    if [ "$installed_version" == "not installed" ]; then
        echo "First time installation of allstarlink-asteriskx-full."
    else
        if dpkg --compare-versions "$installed_version" ge "$deb_version"; then
            echo "Already up to date. Skipping installation."
            exit 1
        fi
    fi
}

backup_asl() {
    if [ -d /etc/asterisk ]; then
        current_time=$(date "+%Y-%m-%d_%H-%M-%S")
        backup_name="asterisk-$current_time"
        echo "Backing up your old Asterisk folder to $backup_name"
        mv -f /etc/asterisk "/etc/$backup_name"
    else
        echo "No existing asterisk folder found, skipping backup."
    fi
}

install_dahdi() {
    dpkg -i "$DAHDI_DKMS" "$DAHDI_TOOLS" || { echo "Failed to install DAHDI packages."; exit 1; }
    modprobe dahdi || { echo "Failed to load DAHDI module."; exit 1; }
    modprobe dahdi_dummy || { echo "Failed to load DAHDI dummy module."; exit 1; }
    if ! lsmod | grep -w "dahdi" > /dev/null; then
        echo "DAHDI module not found, failed to load.";
        exit 1;
    fi
    if ! lsmod | grep -w "dahdi_dummy" > /dev/null; then
        echo "DAHDI dummy module not found, failed to load.";
        exit 1;
    fi
}

uninstall_dahdi() {
    if lsmod | grep -w "dahdi_dummy" > /dev/null; then modprobe -r dahdi_dummy; fi
    if lsmod | grep -w "dahdi" > /dev/null; then modprobe -r dahdi; fi
    if dpkg -l | grep -w "$N_DAHDI_TOOLS" > /dev/null; then dpkg -P "$N_DAHDI_TOOLS"; fi
    if dpkg -l | grep -w "$N_DAHDI_DKMS" > /dev/null; then dpkg -P "$N_DAHDI_DKMS"; fi
}

install_asl() {
    dpkg -i $ASL_DEB || { echo "Failed to install AllStarLink packages."; exit 1; }
}

uninstall_asl() {
    if systemctl list-units --type=service --all | grep -w "asterisk.service" > /dev/null; then
        systemctl stop asterisk
        systemctl disable asterisk
    fi
    if [ -f /usr/local/sbin/astdn.sh ]; then
        /usr/local/sbin/astdn.sh
    fi
    for package in allstar allstar-asterisk-full allstar-asteriskx-full; do
        if dpkg-query -W -f='${binary:Package}\n' | grep -w "^$package$" > /dev/null; then
            dpkg -P "$package"
        fi
    done
}

cleanup_files() {
    rm -f "$DAHDI_DKMS" "$DAHDI_TOOLS" "$ASL_DEB"
}

trap cleanup_files EXIT

check_root
confirm_installation
detect_debian_version
determine_packages
check_installed_version

echo "Starting installation process."

echo "Updating the System."
update_system

echo "Installing required dependencies."
install_dependencies

echo "Downloading required deb packages."
download_deb_files

echo "Removing any existing Dahdi and Allstarlink installations."
backup_asl
uninstall_asl
uninstall_dahdi

echo "Installing Dahdi and Allstarlink."
install_dahdi
install_asl

echo "Cleaning up downloaded files."
cleanup_files

echo "Installation completed successfully."

/usr/local/sbin/asl-menu
