#!/bin/bash

# Set the kernel path and installation directories
KERNEL_PATH="/lib/modules/$(uname -r)/build"
INSTALL="/lib/modules/$(uname -r)/kernel/drivers/wifi"
PKG_BUILD=$(pwd)

# Function to compile the driver
make_target() {
  if [ "$(uname -m)" = "arm" ]; then
    cflags="-mno-outline-atomics -Wno-missing-prototypes" \
    make -C "${KERNEL_PATH}" M="${PKG_BUILD}" || exit 1
  else
    
    make -C "${KERNEL_PATH}" M="${PKG_BUILD}" subdir-ccflags-y="${ccflags}" || exit 1
  fi
}

# Function to install the driver
makeinstall_target() {
  mkdir -p "${INSTALL}/$(get_full_module_dir)/${PKG_NAME}"
  find "${PKG_BUILD}/" -name "*.ko" -not -path '*/\.*' -exec cp {} "${INSTALL}/$(get_full_module_dir)/${PKG_NAME}" \;

  mkdir -p "${INSTALL}/$(get_full_firmware_dir)/w1"
  cp "${PKG_BUILD}/aml_wifi*.txt" "${INSTALL}/$(get_full_firmware_dir)/w1"
}

# Execute the functions
make_target
makeinstall_target

echo "Build and installation completed successfully."