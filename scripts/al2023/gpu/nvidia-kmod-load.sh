#!/usr/bin/env bash

set -Eeuo pipefail

# Exit early if no NVIDIA devices are present
if ! kmod-util has-nvidia-device; then
  echo >&2 "no NVIDIA devices are present, not loading kernel module!"
  exit 0
fi

readonly NVIDIA_VENDOR_ID="10de" # NVIDIA's PCI vendor ID
readonly NVIDIA_GRID_SUBDEVICES=(
  "27b8:1733" # L4:L4-3Q
  "27b8:1735" # L4:L4-6Q
  "27b8:1737" # L4:L4-12Q
)
readonly NVIDIA_PROPRIETARY_SUBDEVICES=(
  "1db1:1212" # P3 instances
  "13f2:113a" # G3 instances
)

# Helper function to check if any device matches a given array of subdevice IDs
device-supports-module-type() {
  local -n device_array=$1
  local device nvidia_subdevice

  for device in "${device_array[@]}"; do
    while IFS= read -r nvidia_subdevice; do
      if [[ "${device}" == "${nvidia_subdevice}" ]]; then
        return 0
      fi
    done < <(lspci -n -mm -d "${NVIDIA_VENDOR_ID}:" | awk '{print $4":"$7}' | tr -d '"')
  done

  return 1
}

# Check if any device supports proprietary drivers (P3 and G3 instances)
device-supports-proprietary() {
  device-supports-module-type NVIDIA_PROPRIETARY_SUBDEVICES
}

# Check if any device supports GRID virtualization
device-supports-grid() {
  device-supports-module-type NVIDIA_GRID_SUBDEVICES
}

# Determine and load the appropriate NVIDIA kernel module
main() {
  local module_name

  if device-supports-grid; then
    module_name="nvidia-grid" # Load grid kmod
  elif device-supports-proprietary; then
    module_name="nvidia-proprietary" # Load proprietary kmod
  else
    module_name="nvidia" # Fallback to open-source kmod for all other devices
  fi

  echo "Loading NVIDIA kernel module: ${module_name}"
  exec kmod-util load "${module_name}"
}

main "$@"
