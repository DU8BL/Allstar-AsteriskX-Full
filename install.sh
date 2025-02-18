#!/bin/bash

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo." >&2
        exit 1
    fi
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
    if [ "$DEBIAN_VERSION" -le 11 ]; then
        LIBCOMERR_PACKAGE="libcomerr2"
        LIBGCC1_PACKAGE="libgcc1"
        LIBIDN_PACKAGE="libidn11"
        ASL_DEB="allstar-asteriskX-full_1.02X-20250218-1_debian11_amd64.deb"
    elif [ "$DEBIAN_VERSION" -ge 12 ]; then
        LIBCOMERR_PACKAGE="libcom-err2"
        LIBGCC1_PACKAGE="libgcc-s1"
        LIBIDN_PACKAGE="libidn12"
        ASL_DEB="allstar-asteriskX-full_1.02X-20250218-1_debian12_amd64.deb"
    else
        echo "Unsupported Debian version. Exiting."
        exit 1
    fi
}

update_system() {
    apt update && apt upgrade -y
}

install_dependencies() {
    apt install -y \
        dkms \
        fxload \
        libasound2 \
        libc6 \
        $LIBCOMERR_PACKAGE \
        libcurl4 \
        $LIBGCC1_PACKAGE \
        libgsm1 \
        $LIBIDN_PACKAGE \
        libiksemel3 \
        libncurses5 \
        libnewt0.52 \
        libogg0 \
        libpopt0 \
        libpri1.4 \
        libspeex1 \
        libstdc++6 \
        libtonezone-dev \
        libusb-0.1-4 \
        libusb-1.0-0 \
        libvorbis0a \
        libvorbisenc2 \
        libwrap0 \
        linux-headers-$(uname -r) \
        perl \
        procps \
        usbutils \
        wget \
        zlib1g
}

download_deb_files() {
    wget -q https://raw.githubusercontent.com/DU8BL/Allstar-AsteriskX-Full/main/allstar-dahdi-linux-dkms_3.1.0.20210216-19_all.deb
    wget -q https://raw.githubusercontent.com/DU8BL/Allstar-AsteriskX-Full/main/allstar-dahdi-linux-tools_3.1.0.20210205-4_amd64.deb
    wget -q https://raw.githubusercontent.com/DU8BL/Allstar-AsteriskX-Full/main/$ASL_DEB
}

install_dahdi() {
    dpkg -i allstar-dahdi-linux-dkms_3.1.0.20210216-19_all.deb
    dpkg -i allstar-dahdi-linux-tools_3.1.0.20210205-4_amd64.deb
    modprobe dahdi
    modprobe dahdi_dummy
}

install_asl() {
    dpkg -i $ASL_DEB
}

cleanup_files() {
    rm -f allstar-dahdi-linux-dkms_3.1.0.20210216-19_all.deb
    rm -f allstar-dahdi-linux-tools_3.1.0.20210205-4_amd64.deb
    rm -f $ASL_DEB
}

check_root

echo "Starting installation process."
detect_debian_version
determine_packages

echo "Updating the System."
update_system

echo "Installing required dependencies."
install_dependencies

echo "Downloading required deb packages."
download_deb_files

echo "Installing Dahdi and Allstarlink"
install_dahdi
install_asl

echo "Cleaning up downloaded files."
cleanup_files

echo "Installation completed successfully."
