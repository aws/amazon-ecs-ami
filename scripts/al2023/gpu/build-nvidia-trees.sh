#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia-branches, under /opt/nvidia/<branch>.
#
# Runs only when nvidia_driver_trees is on (off by default). The trees aren't used yet: the natively installed driver
# still runs the AMI. For each branch:
#
#   1. Download the branch's user-space packages and their dependencies, and check every package's signature.
#   2. Install the packages every branch shares natively. Unpack the version-specific ones into the tree, and keep
#      their headers in <tree>/.rpms so the packages can be recorded in the package database later.
#   3. Build the kernel modules for each flavor listed (open and proprietary with DKMS, GRID from the EC2 vGPU runfile)
#      into <tree>/flavors/<flavor>/lib/modules/<kernel>/extra.
#
# The modules are built in a separate DKMS tree, so the native install's DKMS state and /usr/src are left untouched.
set -Eeuo pipefail

if [[ ${AMI_TYPE:-} != "al2023gpu" || ${NVIDIA_DRIVER_TREES:-false} != "true" ]]; then
    echo "build-nvidia-trees: skipping (AMI_TYPE=${AMI_TYPE:-}, NVIDIA_DRIVER_TREES=${NVIDIA_DRIVER_TREES:-false})"
    exit 0
fi

NV=/opt/nvidia
B=/opt/nvidia-build
CONF=/etc/ecs/nvidia-driver
K=$(uname -r)
EC2_GRID_DRIVER_S3_BUCKET="ec2-linux-nvidia-drivers"

step() { echo; echo "=== $(date -u +%T) $*"; }
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# -------- branches and versions --------
# The default branch's version is the pin the native install uses; the others come from nvidia_driver_tree_versions_al2023.
BRANCHES_FILE=${NVIDIA_BRANCHES_FILE:-/tmp/nvidia-branches}
NVIDIA_DRIVER_VERSION_FILE=${NVIDIA_DRIVER_VERSION_FILE:-/tmp/NVIDIA_DRIVER_VERSION}
declare -A VERSION=() FLAVORS=()
NAMES=()
while read -r name flavors; do
    [[ -z $name || $name == \#* ]] && continue
    NAMES+=("$name")
    FLAVORS[$name]=$flavors
done <"$BRANCHES_FILE"
[[ ${#NAMES[@]} -gt 0 ]] || die "no branches in $BRANCHES_FILE"
VERSION[${NAMES[0]}]=$(grep "^nvidia_driver_version_al2023" "$NVIDIA_DRIVER_VERSION_FILE" | awk -F'"' '{print $2}')
for pair in ${NVIDIA_DRIVER_TREE_VERSIONS:-}; do
    VERSION[${pair%%=*}]=${pair#*=}
done
for name in "${NAMES[@]}"; do
    [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name'"
    echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
done

skip_grid_driver=""
if [[ -n ${SKIP_GRID_DRIVER_REGIONS:-} ]] && echo "$SKIP_GRID_DRIVER_REGIONS" | grep -q -w "${REGION:-}"; then
    skip_grid_driver="true"
    echo "Region ${REGION} is in the skip-GRID list; the GRID flavor is left out"
fi

step "build prerequisites"
sudo dnf install -y "dnf-command(download)" cpio
sudo rm -rf "$B"
sudo mkdir -p "$B/dkms" "$NV" # dkms needs its separate tree to exist

# The packages whose version differs between branches. They're unpacked into each tree instead of installed natively,
# because one host can't install two versions of the same package.
VS_NAMES=(libnvidia-cfg libnvidia-fbc libnvidia-gpucomp libnvidia-ml nvidia-driver nvidia-driver-cuda
    nvidia-driver-cuda-libs nvidia-driver-libs nvidia-fabricmanager nvidia-imex nvidia-kmod-common
    nvidia-libXNVCtrl nvidia-libXNVCtrl-devel nvidia-modprobe nvidia-persistenced nvidia-settings
    nvidia-xconfig xorg-x11-nvidia)
is_vs_name() {
    local n
    for n in "${VS_NAMES[@]}"; do [[ $n == "$1" ]] && return 0; done
    return 1
}
is_nvidia_pkg() { case "$1" in nvidia-* | libnvidia-* | xorg-x11-nvidia-* | kmod-nvidia-* | egl-wayland* | nvidia_*) return 0 ;; *) return 1 ;; esac }

# -------- 1. download each branch's packages --------
# dnf download --resolve fetches the named packages plus the dependencies that aren't installed yet. It satisfies the
# unversioned requirements between NVIDIA packages with the newest provider, so another branch's copies of some
# version-specific packages get pulled in; drop those. The DKMS source packages are build inputs: they conflict with
# each other, so they're downloaded separately, without dependency resolution.
download_branch() { # download_branch NAME
    local name=$1 v=${VERSION[$1]} dest=$B/dl/$1 n rpm nv ver
    sudo mkdir -p "$dest" "$B/kmod/$name"
    local specs=()
    for n in "${VS_NAMES[@]}"; do specs+=("$n-$v"); done
    sudo dnf -y download --resolve --disableplugin=versionlock --destdir="$dest" "${specs[@]}" egl-wayland egl-wayland2
    shopt -s nullglob
    for rpm in "$dest"/*.rpm; do
        nv=$(rpm -qp --qf '%{NAME} %{VERSION}' "$rpm" 2>/dev/null) || die "cannot read $rpm"
        n=${nv% *}
        ver=${nv#* }
        if is_vs_name "$n" && [[ $ver != "$v" ]]; then
            echo "branch $name: dropping $(basename "$rpm"), version $ver"
            sudo rm -f "$rpm"
        fi
    done
    shopt -u nullglob
    sudo rm -f "$dest"/kmod-nvidia-*-dkms-*.rpm
    sudo dnf -y download --disableplugin=versionlock --destdir="$B/kmod/$name" "kmod-nvidia-open-dkms-$v" "kmod-nvidia-latest-dkms-$v"
}
for name in "${NAMES[@]}"; do
    step "download branch $name (${VERSION[$name]})"
    download_branch "$name"
done

# Every downloaded package must pass its signature check before anything is unpacked: the trees are built by unpacking,
# so nothing else checks the signatures.
step "check the signature of every downloaded package"
for key in $(sed -n 's/^gpgkey=//p' /etc/yum.repos.d/amazonlinux.repo /etc/yum.repos.d/amazonlinux-nvidia.repo 2>/dev/null | tr ' ' '\n' | sort -u); do
    sudo rpm --import "${key#file://}" || die "cannot import signing key $key"
done
mapfile -d '' ALL_RPMS < <(find "$B" -name '*.rpm' -print0)
[[ ${#ALL_RPMS[@]} -gt 0 ]] || die "no packages downloaded under $B"
sigs=$(rpm -K "${ALL_RPMS[@]}") || {
    echo "$sigs" >&2
    die "signature check failed"
}
if grep -qv ': digests signatures OK$' <<<"$sigs"; then
    grep -v ': digests signatures OK$' <<<"$sigs" >&2
    die "unsigned or badly signed package among the downloads"
fi
echo "GUARD signatures: OK (${#ALL_RPMS[@]} packages)"

# -------- 2. shared packages: installed natively --------
# A package is shared if every branch downloaded the same file (same name, version and release). None of them may be
# an NVIDIA package.
step "install the packages every branch shares"
SHARED=$B/shared
sudo mkdir -p "$SHARED"
shopt -s nullglob
for rpm in "$B/dl/${NAMES[0]}"/*.rpm; do
    base=$(basename "$rpm")
    in_all=1
    for name in "${NAMES[@]:1}"; do [[ -e "$B/dl/$name/$base" ]] || in_all=0; done
    [[ $in_all == 1 ]] || continue
    is_nvidia_pkg "$base" && continue
    sudo cp "$rpm" "$SHARED/"
done
shared=("$SHARED"/*.rpm)
shopt -u nullglob
echo "shared packages: ${#shared[@]}"
if [[ ${#shared[@]} -gt 0 ]]; then
    sudo dnf -y install --disableplugin=versionlock --setopt=install_weak_deps=False "${shared[@]}"
fi

# -------- 3. kernel modules --------
# Built in a separate DKMS tree ($B/dkms) from sources unpacked under $B/root, so the native install isn't touched.
dkms_build() { # dkms_build MODULE VERSION SRCROOT EXTRA
    local m=$1 v=$2 src=$3 extra=$4 ko
    sudo dkms add -m "$m" -v "$v" --sourcetree "$src" --dkmstree "$B/dkms"
    sudo dkms build -m "$m" -v "$v" -k "$K" --sourcetree "$src" --dkmstree "$B/dkms"
    for ko in "$B/dkms/$m/$v/$K/$(uname -m)/module"/*.ko*; do sudo cp "$ko" "$extra/"; done
}
build_open() { # build_open NAME TREE
    local v=${VERSION[$1]} extra=$2/flavors/open/lib/modules/$K/extra root=$B/root/open-$1
    sudo mkdir -p "$extra" "$root"
    sudo bash -c "rpm2cpio '$B/kmod/$1'/kmod-nvidia-open-dkms-$v-*.rpm | (cd '$root' && cpio -idmu --quiet)"
    dkms_build nvidia "$v" "$root/usr/src" "$extra"
}
build_proprietary() { # build_proprietary NAME TREE
    local v=${VERSION[$1]} extra=$2/flavors/proprietary/lib/modules/$K/extra root=$B/root/proprietary-$1
    sudo mkdir -p "$extra" "$root"
    sudo bash -c "rpm2cpio '$B/kmod/$1'/kmod-nvidia-latest-dkms-$v-*.rpm | (cd '$root' && cpio -idmu --quiet)"
    # Renamed to nvidia-proprietary, as the native install does, so it can't be mistaken for the open build.
    sudo sed -i 's/PACKAGE_NAME="nvidia"/PACKAGE_NAME="nvidia-proprietary"/' "$root/usr/src/nvidia-$v/dkms.conf"
    sudo mv "$root/usr/src/nvidia-$v" "$root/usr/src/nvidia-proprietary-$v"
    dkms_build nvidia-proprietary "$v" "$root/usr/src" "$extra"
}
build_grid() { # build_grid NAME TREE
    local v=${VERSION[$1]} tree=$2 extra=$2/flavors/grid/lib/modules/$K/extra tmp key runfile
    sudo mkdir -p "$extra"
    tmp=$(mktemp -d)
    # Anchored to grid-*/ so it can't match the runfile under latest/.
    key=$(aws s3 ls --recursive "s3://${EC2_GRID_DRIVER_S3_BUCKET}/" --no-sign-request |
        grep "grid-.*NVIDIA-Linux-x86_64-${v}-grid" | sort -k1,2 | awk 'END {print $4}')
    [[ -n $key ]] || die "no GRID runfile for $v in s3://${EC2_GRID_DRIVER_S3_BUCKET}"
    runfile=$(basename "$key")
    aws s3 cp "s3://${EC2_GRID_DRIVER_S3_BUCKET}/${key}" "$tmp/$runfile" --no-sign-request
    chmod +x "$tmp/$runfile"
    sudo "$tmp/$runfile" --extract-only --target "$tmp/extract"
    sudo make -C "$tmp/extract/kernel-open" -j"$(nproc)" SYSSRC="/lib/modules/$K/build" modules
    sudo find "$tmp/extract/kernel-open" -name '*.ko' -exec cp {} "$extra/" \;
    # The GRID licensing daemon ships only in the runfile.
    sudo install -D -m0755 "$tmp/extract/nvidia-gridd" "$tree/grid-extra/usr/bin/nvidia-gridd"
    sudo install -D -m0644 "$tmp/extract/init-scripts/systemd/nvidia-gridd.service" \
        "$tree/grid-extra/usr/lib/systemd/system/nvidia-gridd.service"
    sudo install -D -m0644 "$tmp/extract/gridd.conf.template" "$tree/grid-extra/etc/nvidia/gridd.conf.template"
    sudo rm -rf "$tmp"
}

# -------- 4. one tree per branch --------
# <tree>/.rpms keeps only each package's lead, signature header and main header: recording a package in the database
# (rpm --justdb) reads the header and never the payload.
rpm_header_only() { # rpm_header_only SRC DST
    sudo python3 -c '
import struct, sys
src, dst = sys.argv[1:]
data = open(src, "rb").read()
def header_end(off):
    if data[off:off + 3] != b"\x8e\xad\xe8":
        sys.exit("not an RPM header at offset %d in %s" % (off, src))
    nindex, hsize = struct.unpack(">II", data[off + 8:off + 16])
    return off + 16 + nindex * 16 + hsize
off = header_end(96)
off = (off + 7) // 8 * 8
off = header_end(off)
open(dst, "wb").write(data[:off])
' "$1" "$2"
}
build_tree() { # build_tree NAME
    local name=$1 v=${VERSION[$1]} tree=$NV/$1 rpm base flavor
    step "tree $name ($v): unpack the version-specific packages"
    sudo rm -rf "$tree"
    sudo mkdir -p "$tree/.rpms"
    shopt -s nullglob
    for rpm in "$B/dl/$name"/*.rpm; do
        base=$(basename "$rpm")
        [[ -e "$SHARED/$base" ]] && continue
        sudo bash -c "rpm2cpio '$rpm' | (cd '$tree' && cpio -idmu --quiet)"
        rpm_header_only "$rpm" "$tree/.rpms/$base"
    done

    # Guard: every version-specific package is in the tree exactly once, at this branch's version.
    local -A seen=()
    local r nv n ver bad=0
    for r in "$tree/.rpms"/*.rpm; do
        nv=$(rpm -qp --qf '%{NAME} %{VERSION}' "$r" 2>/dev/null) || die "tree $name: cannot read $r"
        n=${nv% *}
        ver=${nv#* }
        is_vs_name "$n" || continue
        [[ $ver == "$v" ]] || {
            echo "GUARD tree $name: $n is at $ver, not $v" >&2
            bad=1
        }
        seen[$n]=$((${seen[$n]:-0} + 1))
    done
    for n in "${VS_NAMES[@]}"; do
        [[ ${seen[$n]:-0} == 1 ]] || {
            echo "GUARD tree $name: $n found ${seen[$n]:-0} times" >&2
            bad=1
        }
    done
    [[ $bad == 0 ]] || die "tree $name ($v): version-specific packages are wrong"
    echo "GUARD tree $name: OK (${#VS_NAMES[@]} version-specific packages, each once at $v)"

    # Guard: the header-only packages register with the flags used at boot, into a scratch database.
    local db n_in n_db
    db=$(mktemp -d)
    sudo rpm --dbpath "$db" --initdb
    n_in=$(find "$tree/.rpms" -name '*.rpm' | wc -l)
    sudo rpm --dbpath "$db" -i --justdb --noscripts --nodeps --nodigest --nosignature "$tree/.rpms"/*.rpm ||
        die "tree $name: the package headers don't register"
    n_db=$(sudo rpm --dbpath "$db" -qa | wc -l)
    [[ $n_db == "$n_in" ]] || die "tree $name: $n_db of $n_in package headers registered"
    sudo rm -rf "$db"
    echo "GUARD tree $name: package headers register ($n_db)"

    # The package list, for recording the packages at boot.
    for r in "$tree/.rpms"/*.rpm; do
        rpm -qp --qf '%{NAME}-%{EPOCH}:%{VERSION}-%{RELEASE}.%{ARCH}\n' "$r" 2>/dev/null | sed 's/-(none):/-0:/'
    done | sort | sudo tee "$tree/manifest.install" >/dev/null
    shopt -u nullglob

    for flavor in ${FLAVORS[$name]}; do
        if [[ $flavor == grid && -n $skip_grid_driver ]]; then continue; fi
        step "tree $name ($v): $flavor kernel modules"
        case $flavor in
        open) build_open "$name" "$tree" ;;
        proprietary) build_proprietary "$name" "$tree" ;;
        grid) build_grid "$name" "$tree" ;;
        *) die "branch $name: unknown flavor '$flavor'" ;;
        esac
        sudo strip -g --strip-unneeded "$tree/flavors/$flavor/lib/modules/$K/extra"/*.ko 2>/dev/null || true
        echo "tree $name: $flavor: $(find "$tree/flavors/$flavor/lib/modules/$K/extra" -name '*.ko*' | wc -l) modules"
    done
}
for name in "${NAMES[@]}"; do build_tree "$name"; done

# -------- 5. build-time effects of the packages' install scripts --------
# The unpacked packages' scripts never run. nvidia-persistenced's creates its user and group.
sudo getent group nvidia-persistenced >/dev/null || sudo groupadd -r nvidia-persistenced
sudo getent passwd nvidia-persistenced >/dev/null ||
    sudo useradd -r -g nvidia-persistenced -d / -s /sbin/nologin -c "NVIDIA Persistence Daemon" nvidia-persistenced

# The branches and versions built, default first, for boot-time selection.
sudo mkdir -p "$CONF"
for name in "${NAMES[@]}"; do echo "$name=${VERSION[$name]}"; done | sudo tee "$CONF/branches" >/dev/null

step "sizes"
for name in "${NAMES[@]}"; do
    echo "SIZE $name: $(sudo du -sh "$NV/$name" | cut -f1)"
done
echo "SIZE total: $(sudo du -sh "$NV" | cut -f1)"
sudo rm -rf "$B"
echo "build-nvidia-trees: done"
