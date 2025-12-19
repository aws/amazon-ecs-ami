#!/bin/bash
set -e

# Neuron inf1 downgrade script
# Detects inf1 instances and downgrades neuron driver to compatible version

CACHE_DIR="/opt/ecs/neuron/inf1-rpms"

# Log a message to stderr (systemd provides timestamps)
# Args: message to log
log() {
    echo "$*" >&2
}

# Detect inf1 hardware using PCI device IDs
# inf1 instances have Neuron devices with IDs: 0x7064, 0x7065, 0x7066, or 0x7067
# Returns: 0 if inf1 detected, 1 if not inf1
detect_inf1_hardware() {
    log "Detecting inf1 hardware via PCI devices"

    # Check for inf1 Neuron device IDs
    if lspci -n | grep -q "1d0f:\(7064\|7065\|7066\|7067\)"; then
        log "inf1 Neuron device detected"
        return 0
    fi

    log "No inf1 Neuron devices found"
    return 1
}

# Downgrade neuron packages to inf1-compatible versions
# Uses cached RPM packages and locks ALL neuron package versions to prevent updates
# Returns 0 on success, 1 on failure
downgrade_neuron_packages() {
    log "Starting neuron package downgrade for inf1"

    # aws-neuronx-dkms installation calls `update-pciids || true` to do a best effort PCI ID database
    # update. However, this makes the installation hang if the instance does not have Internet
    # access. Since we update the PCI ID database during AMI build, we can skip it during
    # package installation. To do so, we pass a no-op update-pciids command to the package
    # installation command as an override.
    local no_op_dir
    no_op_dir=$(mktemp -d)
    if [[ -z "$no_op_dir" ]]; then
        log "ERROR: Failed to create temporary directory"
        return 1
    fi
    cat > "$no_op_dir/update-pciids" << 'EOF'
#!/bin/bash
echo "update-pciids: skipped (AMI already has current PCI database)" >&2
exit 0
EOF
    chmod +x "$no_op_dir/update-pciids"

    # Set up cleanup trap to remove no-op directory
    trap "rm -rf '$no_op_dir'" EXIT

    # Find all cached RPM files
    local cached_rpms
    cached_rpms=$(find "$CACHE_DIR" -name "*.rpm" 2>/dev/null)

    if [[ -z "$cached_rpms" ]]; then
        log "ERROR: No cached inf1-compatible packages found in $CACHE_DIR"
        return 1
    fi

    log "Found cached packages:"
    echo "$cached_rpms" | while read -r rpm; do
        log "  $(basename "$rpm")"
    done

    # Process each cached RPM
    while IFS= read -r rpm_file; do
        [[ -n "$rpm_file" ]] || continue

        # Extract package name from RPM filename
        local package_name
        package_name=$(rpm -qp --queryformat '%{NAME}' "$rpm_file" 2>/dev/null)

        if [[ -z "$package_name" ]]; then
            log "WARNING: Could not determine package name for $rpm_file, skipping"
            continue
        fi

        log "Processing package: $package_name"

        # Check current version
        local current_version target_version
        current_version=$(rpm -q "$package_name" --queryformat '%{VERSION}' 2>/dev/null || echo "none")
        target_version=$(rpm -qp --queryformat '%{VERSION}' "$rpm_file" 2>/dev/null)

        if [[ -z "$target_version" ]]; then
            log "ERROR: Could not determine target version for $rpm_file"
            return 1
        fi

        log "Current $package_name version: $current_version"
        log "Target $package_name version: $target_version"

        # Skip if already at target version
        if [[ "$current_version" == "$target_version" ]]; then
            log "$package_name already at target version, skipping"
            continue
        fi

        # Remove current package
        log "Removing current $package_name"
        if ! rpm -e --nodeps "$package_name" 2>/dev/null; then
            log "WARNING: Failed to remove $package_name, may not be installed"
        fi

        # Install inf1-compatible version using PATH override macro
        log "Installing inf1-compatible $package_name"
        if rpm --define "_install_script_path $no_op_dir:/sbin:/bin:/usr/sbin:/usr/bin" -i "$rpm_file"; then
            log "$package_name downgrade successful"
        else
            log "ERROR: Failed to install inf1-compatible $package_name"
            return 1
        fi
    done <<< "$cached_rpms"

    # Lock all known neuron packages to prevent partial updates
    local all_neuron_packages=("aws-neuronx-dkms" "aws-neuronx-tools" "aws-neuronx-oci-hook")
    log "Locking all neuron packages: ${all_neuron_packages[*]}"
    if dnf --cacheonly versionlock add "${all_neuron_packages[@]}"; then
        log "Package version locking successful"
    else
        log "WARNING: Failed to lock some packages"
    fi

    log "Neuron package downgrade completed successfully"
}

# Main function - orchestrates hardware detection and conditional downgrade
# Exit code: 0 on success, 1 on failure
main() {
    log "Starting neuron inf1 downgrade service"

    # Detect inf1 hardware
    if ! detect_inf1_hardware; then
        log "Non-inf1 hardware detected, no action needed"
        log "Neuron inf1 downgrade service completed"
        return 0
    fi

    log "inf1 hardware detected, proceeding with downgrade"
    if ! downgrade_neuron_packages; then
        log "ERROR: Neuron package downgrade failed"
        return 1
    fi

    log "Neuron inf1 downgrade service completed"
}

main "$@"
