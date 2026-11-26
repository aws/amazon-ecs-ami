#!/usr/bin/env bash
# Functions that build a per-version NVIDIA driver tree for each branch in nvidia_driver_branches_al2023, under
# /opt/nvidia/<branch>. install-nvidia-driver.sh sources this file and calls them after the native install, only when
# nvidia_driver_trees_al2023 is on (off by default). So far they download and check each branch's packages, unpack
# them into the branch's tree, and build the branch's kernel modules into it. Nothing reads the trees yet: the native
# driver still runs the AMI.

TREES_BUILD_DIR=/opt/nvidia-build # scratch space for the build, removed at the end
TREES_DIR=/opt/nvidia             # the trees, one per branch
NVIDIA_DRIVER_VERSION_FILE=${NVIDIA_DRIVER_VERSION_FILE:-/tmp/NVIDIA_DRIVER_VERSION}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# read_driver_branches: fill NAMES, FLAVORS and VERSION from NVIDIA_DRIVER_BRANCHES and NVIDIA_DRIVER_VERSION.
#
# Packer passes nvidia_driver_branches_al2023 as "name=flavor,flavor" pairs. Each branch's full version is pinned in
# NVIDIA_DRIVER_VERSION as nvidia_driver_version_al2023_<name>, which check-update.sh keeps current; a branch without
# one fails the build.
NAMES=()                         # branch names
declare -A FLAVORS=() VERSION=() # flavors and version of each branch, by name
read_driver_branches() {
    local pair name flavor
    # Each "pb=open,grid" pair adds "pb" to NAMES and "open grid" to FLAVORS[pb]
    for pair in ${NVIDIA_DRIVER_BRANCHES:-}; do
        name=${pair%%=*}
        NAMES+=("$name")
        FLAVORS[$name]=${pair#*=}
        FLAVORS[$name]=${FLAVORS[$name]//,/ }
    done
    [[ ${#NAMES[@]} -gt 0 ]] || die "no branches in NVIDIA_DRIVER_BRANCHES"

    # VERSION[pb] from nvidia_driver_version_al2023_pb, VERSION[lts] from nvidia_driver_version_al2023_lts
    for name in "${NAMES[@]}"; do
        VERSION[$name]=$(pinned_version "nvidia_driver_version_al2023_$name")
    done

    # Each branch needs a version and at least one flavor, and every flavor must be open, proprietary or grid
    for name in "${NAMES[@]}"; do
        [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name' in $NVIDIA_DRIVER_VERSION_FILE"
        [[ -n ${FLAVORS[$name]} ]] || die "no kernel module flavors for branch '$name'"
        for flavor in ${FLAVORS[$name]}; do
            case $flavor in
            open | proprietary | grid) ;;
            *) die "branch $name: unknown flavor '$flavor'" ;;
            esac
        done
        echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
    done
}
# pinned_version KEY: the version NVIDIA_DRIVER_VERSION pins for KEY, by exact key, so _al2023 doesn't match _al2023_pb
pinned_version() {
    awk -F'"' -v key="$1" '$1 ~ "^" key " *= *$" {print $2}' "$NVIDIA_DRIVER_VERSION_FILE"
}

# download_branch_packages NAME PACKAGE...: download branch NAME's version of the version-specific PACKAGEs, the
# DKMS source packages its flavors build from, and check every signature.
#
# Each branch's packages are downloaded in one dnf transaction, so dnf resolves them together and every dependency comes
# out at the branch's version, plus the other dependencies the host doesn't have yet (egl-wayland for 580, egl-wayland2
# for 595). A branch whose version is already installed is downloaded with reinstall: dnf install skips installed
# packages.
download_branch_packages() {
    local name=$1 version=${VERSION[$1]} download_dir=$TREES_BUILD_DIR/download/$1 dkms_dir=$TREES_BUILD_DIR/dkms/$1
    shift
    local package flavor rpm_file result action=install
    local package_specs=() dkms_packages=() rpm_files=()
    sudo mkdir -p "$download_dir" "$dkms_dir"

    for package in "$@"; do package_specs+=("$package-$version"); done
    if [[ $(rpm -q --qf '%{VERSION}' nvidia-driver-cuda 2>/dev/null) == "$version" ]]; then
        action=reinstall
    fi
    sudo dnf -y "$action" --downloadonly --downloaddir="$download_dir" "${package_specs[@]}"

    # dnf has to resolve a kmod-nvidia-*-dkms package, since nvidia-kmod-common requires nvidia-kmod at the same version
    # and only those provide it, so they can't be excluded from the transaction. They're build inputs, downloaded per
    # flavor below, so the resolved copy is removed.
    sudo rm -f "$download_dir"/kmod-nvidia-*-dkms-*.rpm
    echo "branch $name: packages:"
    rpm -qp --nosignature --qf '  %{NAME} %{VERSION}\n' "$download_dir"/*.rpm | sort

    # The DKMS source packages each branch builds its kernel modules from, one per flavor it lists. They conflict with
    # each other, so they're downloaded without dependency resolution. The GRID flavor comes from the GRID runfile
    # instead.
    for flavor in ${FLAVORS[$name]}; do
        case $flavor in
        open) dkms_packages+=("kmod-nvidia-open-dkms-$version") ;;
        proprietary) dkms_packages+=("kmod-nvidia-latest-dkms-$version") ;;
        esac
    done
    [[ ${#dkms_packages[@]} -eq 0 ]] ||
        sudo dnf -y download --destdir="$dkms_dir" "${dkms_packages[@]}"

    # dnf checks the packages only against the repo metadata, which isn't signed (repo_gpgcheck=0), and the packages are
    # unpacked rather than installed, so no install transaction checks their signatures either. Each one must be signed
    # by a key the native install imported. rpmkeys exits 0 for an unsigned package, so the output is matched.
    shopt -s nullglob
    rpm_files=("$download_dir"/*.rpm "$dkms_dir"/*.rpm)
    shopt -u nullglob
    for rpm_file in "${rpm_files[@]}"; do
        result=$(rpmkeys --checksig "$rpm_file") || die "branch $name: $result"
        [[ $result == *"signatures OK" ]] || die "branch $name: not signed by an imported key: $result"
    done
    echo "branch $name: ${#rpm_files[@]} packages signed by an imported key"
}

# unpack_branch BRANCH: unpack each of the branch's downloaded packages into its tree, /opt/nvidia/<branch>. The tree
# ends up holding the driver's files at the same paths an install would put them under /, e.g.
# /opt/nvidia/pb/usr/bin/nvidia-smi. The packages are unpacked, not installed, because one host can't install two
# versions of the same package.
unpack_branch() {
    local branch=$1 package
    local tree_dir=$TREES_DIR/$branch
    sudo mkdir -p "$tree_dir"
    for package in "$TREES_BUILD_DIR/download/$branch"/*.rpm; do
        unpack_package "$package" "$tree_dir" || die "branch $branch: cannot unpack $package"
    done
}

# unpack_package PACKAGE TARGET_DIR: unpack the files in an RPM package into TARGET_DIR, without installing it.
# rpm2cpio turns the package into a cpio archive, and cpio extracts it (-i), creating directories as needed (-d) and
# keeping each file's modification time from the package (-m), as an install would.
unpack_package() {
    local package=$1 target_dir=$2
    local - # pipefail for this function only, so a failed rpm2cpio fails the unpack too
    set -o pipefail
    # cpio extracts into the current directory, so cd into TARGET_DIR first; the parentheses run that in a subshell,
    # so the build's own current directory doesn't change
    rpm2cpio "$package" | (cd "$target_dir" && sudo cpio -idm --quiet)
}

# build_branch_modules BRANCH KERNEL SKIP_GRID: build the branch's kernel modules for KERNEL, once for each flavor the
# branch lists (open, proprietary, grid), into its tree at flavors/<flavor>/lib/modules/<kernel>/extra. SKIP_GRID is
# install-nvidia-driver.sh's skip_grid_driver: set in the regions that have no GRID bucket, where there's no grid
# source to build from.
#
# The modules are built now, at build time, so that at boot an instance only copies its flavor's modules into
# /lib/modules: no DKMS build and no initramfs rebuild at boot.
build_branch_modules() {
    local branch=$1 kernel=$2 skip_grid=$3 flavor source_dir
    for flavor in ${FLAVORS[$branch]}; do
        # Each flavor builds from a different source: open and proprietary from the DKMS source packages downloaded
        # with the branch's packages, grid from NVIDIA's GRID runfile in S3
        case $flavor in
        open) source_dir=$(unpack_dkms_source "$branch" open kmod-nvidia-open-dkms) ;;
        proprietary) source_dir=$(unpack_dkms_source "$branch" proprietary kmod-nvidia-latest-dkms) ;;
        grid)
            if [[ -n $skip_grid ]]; then
                continue
            fi
            source_dir=$(extract_grid_source "$branch")
            ;;
        esac
        build_flavor_modules "$branch" "$flavor" "$source_dir" "$kernel"
    done
}

# build_flavor_modules BRANCH FLAVOR SOURCE_DIR KERNEL: build the kernel modules from the DKMS source in
# SOURCE_DIR/nvidia-<version> and copy them into the branch's tree.
build_flavor_modules() {
    local branch=$1 flavor=$2 source_dir=$3 kernel=$4
    local version=${VERSION[$branch]}
    # DKMS keeps its own record of every module it has built. A separate one in the scratch space (--dkmstree) keeps
    # these builds apart from each other.
    local dkms_dir=$TREES_BUILD_DIR/dkms-tree/$branch-$flavor
    local module_dir=$TREES_DIR/$branch/flavors/$flavor/lib/modules/$kernel/extra
    sudo mkdir -p "$dkms_dir" "$module_dir"

    # Register the source with DKMS, then build it for KERNEL. On a failed build, show the end of the compiler's log,
    # since DKMS itself only says that the build failed.
    sudo dkms add -m nvidia -v "$version" --sourcetree "$source_dir" --dkmstree "$dkms_dir"
    if ! sudo dkms build -m nvidia -v "$version" -k "$kernel" --sourcetree "$source_dir" --dkmstree "$dkms_dir"; then
        sudo tail -n 40 "$dkms_dir/nvidia/$version/build/make.log" >&2
        die "branch $branch: building the $flavor kernel modules failed"
    fi

    # Copy the modules into the tree and strip their debug symbols (strip -g), which nothing on the AMI reads and which
    # make up most of each file's size
    sudo cp "$dkms_dir/nvidia/$version/$kernel/$(uname -m)/module"/*.ko "$module_dir/"
    sudo strip -g "$module_dir"/*.ko
}

# unpack_dkms_source BRANCH FLAVOR PACKAGE: unpack the DKMS source package the open or proprietary flavor builds from
# (downloaded by download_branch_packages into the scratch space's dkms/<branch>), and print the directory to build
# from. The package puts its source in usr/src/nvidia-<version>.
unpack_dkms_source() {
    local branch=$1 flavor=$2 package=$3
    local unpack_dir=$TREES_BUILD_DIR/source/$branch-$flavor
    sudo mkdir -p "$unpack_dir"
    unpack_package "$TREES_BUILD_DIR/dkms/$branch/$package-${VERSION[$branch]}"-*.rpm "$unpack_dir" ||
        die "branch $branch: cannot unpack $package"
    echo "$unpack_dir/usr/src"
}

# extract_grid_source BRANCH: get the grid flavor's source from NVIDIA's GRID runfile for the branch's version, in
# install-nvidia-driver.sh's EC2_GRID_DRIVER_S3_BUCKET, and print the directory to build from.
#
# The runfile's kernel-open directory is the open modules' source with the GRID changes. Its dkms.conf is only a
# template that NVIDIA's installer fills in, and the installer would install the driver natively, so the runfile is
# only extracted and the dkms.conf is written here.
extract_grid_source() {
    local branch=$1
    local version=${VERSION[$branch]}
    local source_dir=$TREES_BUILD_DIR/source/$branch-grid
    local extract_dir=$TREES_BUILD_DIR/grid-runfile
    local runfile_key runfile
    local - # pipefail for this function only, so a failed S3 listing fails the lookup too
    set -o pipefail

    # Find the runfile: list the bucket, keep this version's runfiles, and take the newest upload (sort by the listing's date and time columns). The 4th column is the file's path in the bucket.
    runfile_key=$(aws s3 ls --recursive "s3://${EC2_GRID_DRIVER_S3_BUCKET}/" --no-sign-request |
        grep "NVIDIA-Linux-x86_64-${version}" | sort -k1,2 | tail -1 | awk '{print $4}') || true
    [[ -n $runfile_key ]] || die "branch $branch: no GRID runfile for $version in s3://${EC2_GRID_DRIVER_S3_BUCKET}"

    # Download it as the build user, into a temporary directory that user owns, and extract it without installing.
    # The previous branch's extracted runfile is removed first, since the extract needs an empty directory.
    runfile=$(mktemp -d)/grid.run
    aws s3 cp "s3://${EC2_GRID_DRIVER_S3_BUCKET}/$runfile_key" "$runfile" --no-sign-request --no-progress >&2
    chmod +x "$runfile"
    sudo rm -rf "$extract_dir"
    sudo "$runfile" --extract-only --target "$extract_dir" >&2
    rm -rf "$(dirname "$runfile")"

    # DKMS builds from <source_dir>/nvidia-<version>
    sudo mkdir -p "$source_dir/nvidia-$version"
    sudo cp -a "$extract_dir/kernel-open/." "$source_dir/nvidia-$version/"

    # The same settings as the dkms.conf in the open flavor's DKMS package, except that the modules are built in the
    # source directory itself, so there's no BUILT_MODULE_LOCATION. The \$ are left for DKMS to fill in at build time.
    sudo tee "$source_dir/nvidia-$version/dkms.conf" >/dev/null <<EOF
PACKAGE_NAME="nvidia"
PACKAGE_VERSION="$version"
AUTOINSTALL="yes"

MAKE[0]="'make' \${parallel_jobs+-j\$parallel_jobs} KERNEL_UNAME=\${kernelver} IGNORE_PREEMPT_RT_PRESENCE=1 IGNORE_XEN_PRESENCE=1 modules"

BUILT_MODULE_NAME[0]="nvidia"
DEST_MODULE_LOCATION[0]="/extra"
BUILT_MODULE_NAME[1]="nvidia-modeset"
DEST_MODULE_LOCATION[1]="/extra"
BUILT_MODULE_NAME[2]="nvidia-drm"
DEST_MODULE_LOCATION[2]="/extra"
BUILT_MODULE_NAME[3]="nvidia-uvm"
DEST_MODULE_LOCATION[3]="/extra"
BUILT_MODULE_NAME[4]="nvidia-peermem"
DEST_MODULE_LOCATION[4]="/extra"
EOF
    echo "$source_dir"
}
