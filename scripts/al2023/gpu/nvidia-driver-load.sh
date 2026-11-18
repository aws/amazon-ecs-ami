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
  "1db5:1249" # P3dn instances
  "13f2:113a" # G3 instances
)
# GPUs that need the LTS driver branch (580) instead of the default PB (595): P3 and G3 instances, whose GPUs NVIDIA
# no longer supports after 580
readonly NVIDIA_LTS_SUBDEVICES=(
  "1db1:1212" # P3 instances
  "1db5:1249" # P3dn instances
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

# Check if any device needs the LTS driver branch (P3 and G3 instances)
device-needs-lts() {
  device-supports-module-type NVIDIA_LTS_SUBDEVICES
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

  # Only on AMIs built with the per-version driver trees (nvidia_driver_trees_al2023), which put one tree per branch
  # under /opt/nvidia (checking lts's, since nvlsm also installs into /opt/nvidia): pick this instance's branch,
  # pb unless the GPU needs lts.
  if [[ -d /opt/nvidia/lts ]]; then
    local branch="pb"
    if device-needs-lts; then
      branch="lts"
    fi
  fi

  echo "Loading NVIDIA kernel module: ${module_name}"
  exec kmod-util load "${module_name}"
}

main "$@"
