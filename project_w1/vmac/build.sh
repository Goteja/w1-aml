#!/bin/bash

# Set the kernel path and installation directories
KERNEL_PATH="/lib/modules/$(uname -r)/build"
INSTALL="/lib/modules/$(uname -r)/kernel/drivers/wifi"
PKG_BUILD=$(pwd)
PKG_NAME="w1-wifi"

# Function to get module directory
get_full_module_dir() {
    echo "extra"
}

# Function to get firmware directory
get_full_firmware_dir() {
    echo "firmware"
}

# Function to compile the driver
make_target() {
    CFLAGS="-mno-outline-atomics -Wno-missing-prototypes" \
    make -C "${KERNEL_PATH}" M="${PKG_BUILD}" || exit 1
}

# Function to install the driver
makeinstall_target() {
    mkdir -p "${INSTALL}/$(get_full_module_dir)/${PKG_NAME}"
    find "${PKG_BUILD}/" -name "*.ko" -not -path '*/\.*' -exec cp {} "${INSTALL}/$(get_full_module_dir)/${PKG_NAME}" \;

    mkdir -p "${INSTALL}/$(get_full_firmware_dir)/w1"
    cp "${PKG_BUILD}/aml_wifi"*.txt "${INSTALL}/$(get_full_firmware_dir)/w1" || true
}

# Execute the functions
make_target
makeinstall_target

echo "Build and installation completed successfully."
