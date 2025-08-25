#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
#
# - Collects Docker daemon and Amazon ECS Container Agent logs on Amazon Linux,
#   Redhat 7, Debian 8.
# - Collects general operating system logs.
# - Optional ability to enable debug mode for the Docker daemon and Amazon ECS
#   Container Agent on Amazon Linux variants, such as the Amazon ECS-optimized
#   AMI. For usage information, see --help.

export LANG="C"
export LC_ALL="C"

# Collection configuration

# curdir is the working root of collection.
curdir="$(dirname "$0")"
# collectdir is where all collected informaton is placed under. This
# services as the top level for this script's operation.
readonly collectdir="${curdir}/collect"

# datetime is the date and time when the script was executed used in pack()
datetime=`date +%Y%m%d%H%M`

# pack_name is the name of the resulting tarball. This will generally
# be collect-i-ffffffffffffffffff-YYYYMMDDHHmm, where i-ffffffffffffffffff is the
# instance id and YYYYMMDDHHmm is date and time.
pack_name="collect"

# Shared check variables

# info_system is where the checks' data is placed.
info_system="${collectdir}/system"
# pkgtype is the detected packaging system used on the host (eg: yum, deb)
pkgtype=''  # defined in get_pkgtype
# jsonformatter is the detected tool to process JSON installed on the host
jsonformatter=''
# init_type is the operating system type used for casing check behavior.
init_type=''  # defined in get_init_type
progname='' # defined in parse_options
# dstdir is the destination where the logs collected are placed.
dstdir=''  # defined in several routines

# Script run defaults

mode='brief' # defined in parse_options

# Sanitization Variables

vars_to_redact=("ECS_ENGINE_AUTH_DATA" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_SESSION_TOKEN")

declare -A ecs_config_allowlist
ecs_config_allowlist=(
    ["ECS_CLUSTER"]=1                            ["ECS_RESERVED_PORTS"]=1                           ["ECS_RESERVED_PORTS_UDP"]=1
    ["ECS_ENGINE_AUTH_TYPE"]=1                   ["AWS_DEFAULT_REGION"]=1                           ["DOCKER_HOST"]=1
    ["ECS_LOGLEVEL"]=1                           ["ECS_LOGLEVEL_ON_INSTANCE"]=1                     ["ECS_LOGFILE"]=1
    ["ECS_CHECKPOINT"]=1                         ["ECS_DATADIR"]=1                                  ["ECS_UPDATES_ENABLED"]=1
    ["ECS_DISABLE_METRICS"]=1                    ["ECS_POLL_METRICS"]=1                             ["ECS_POLLING_METRICS_WAIT_DURATION"]=1
    ["ECS_PULL_DEPENDENT_CONTAINERS_UPFRONT"]=1  ["ECS_RESERVED_MEMORY"]=1                          ["ECS_AVAILABLE_LOGGING_DRIVERS"]=1
    ["ECS_DISABLE_PRIVILEGED"]=1                 ["ECS_SELINUX_CAPABLE"]=1                          ["ECS_APPARMOR_CAPABLE"]=1
    ["ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION"]=1  ["ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION_JITTER"]=1 ["ECS_MANIFEST_PULL_TIMEOUT"]=1
    ["ECS_CONTAINER_STOP_TIMEOUT"]=1             ["ECS_CONTAINER_START_TIMEOUT"]=1                  ["ECS_CONTAINER_CREATE_TIMEOUT"]=1
    ["ECS_ENABLE_TASK_IAM_ROLE"]=1               ["ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST"]=1        ["ECS_DISABLE_IMAGE_CLEANUP"]=1
    ["ECS_IMAGE_CLEANUP_INTERVAL"]=1             ["ECS_IMAGE_MINIMUM_CLEANUP_AGE"]=1                ["NON_ECS_IMAGE_MINIMUM_CLEANUP_AGE"]=1
    ["ECS_NUM_IMAGES_DELETE_PER_CYCLE"]=1        ["ECS_IMAGE_PULL_BEHAVIOR"]=1                      ["ECS_IMAGE_PULL_INACTIVITY_TIMEOUT"]=1
    ["ECS_IMAGE_PULL_TIMEOUT"]=1                 ["ECS_INSTANCE_ATTRIBUTES"]=1                      ["ECS_ENABLE_TASK_ENI"]=1
    ["ECS_ENABLE_HIGH_DENSITY_ENI"]=1            ["ECS_CNI_PLUGINS_PATH"]=1                         ["ECS_AWSVPC_BLOCK_IMDS"]=1
    ["ECS_AWSVPC_ADDITIONAL_LOCAL_ROUTES"]=1     ["ECS_ENABLE_CONTAINER_METADATA"]=1                ["ECS_HOST_DATA_DIR"]=1
    ["ECS_ENABLE_TASK_CPU_MEM_LIMIT"]=1          ["ECS_CGROUP_PATH"]=1                              ["ECS_CGROUP_CPU_PERIOD"]=1
    ["ECS_AGENT_HEALTHCHECK_HOST"]=1             ["ECS_ENABLE_CPU_UNBOUNDED_WINDOWS_WORKAROUND"]=1  ["ECS_ENABLE_MEMORY_UNBOUNDED_WINDOWS_WORKAROUND"]=1
    ["ECS_TASK_METADATA_RPS_LIMIT"]=1            ["ECS_SHARED_VOLUME_MATCH_FULL_CONFIG"]=1          ["ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM"]=1
    ["ECS_CONTAINER_INSTANCE_TAGS"]=1            ["ECS_ENABLE_UNTRACKED_IMAGE_CLEANUP"]=1           ["ECS_EXCLUDE_UNTRACKED_IMAGE"]=1
    ["ECS_DISABLE_DOCKER_HEALTH_CHECK"]=1        ["ECS_NVIDIA_RUNTIME"]=1                           ["ECS_ALTERNATE_CREDENTIAL_PROFILE"]=1
    ["ECS_ENABLE_SPOT_INSTANCE_DRAINING"]=1      ["ECS_LOG_ROLLOVER_TYPE"]=1                        ["ECS_LOG_OUTPUT_FORMAT"]=1
    ["ECS_LOG_MAX_FILE_SIZE_MB"]=1               ["ECS_LOG_MAX_ROLL_COUNT"]=1                       ["ECS_LOG_DRIVER"]=1
    ["ECS_LOG_OPTS"]=1                           ["ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE"]=1    ["ECS_FSX_WINDOWS_FILE_SERVER_SUPPORTED"]=1
    ["ECS_ENABLE_RUNTIME_STATS"]=1               ["ECS_EXCLUDE_IPV6_PORTBINDING"]=1                 ["ECS_WARM_POOLS_CHECK"]=1
    ["ECS_SKIP_LOCALHOST_TRAFFIC_FILTER"]=1      ["ECS_ALLOW_OFFHOST_INTROSPECTION_ACCESS"]=1       ["ECS_OFFHOST_INTROSPECTION_INTERFACE_NAME"]=1
    ["ECS_ENABLE_GPU_SUPPORT"]=1                 ["HTTP_PROXY"]=1                                   ["NO_PROXY"]=1
    ["ECS_GMSA_SUPPORTED"]=1                     ["CREDENTIALS_FETCHER_HOST"]=1                     ["CREDENTIALS_FETCHER_SECRET_NAME_FOR_DOMAINLESS_GMSA"]=1
    ["ECS_DYNAMIC_HOST_PORT_RANGE"]=1            ["ECS_TASK_PIDS_LIMIT"]=1                          ["ECS_EBSTA_SUPPORTED"]=1
    ["ECS_SKIP_LOCALHOST_TRAFFIC_FILTER"]=1      ["ECS_ALLOW_OFFHOST_INTROSPECTION_ACCESS"]=1       ["ECS_OFFHOST_INTROSPECTION_INTERFACE_NAME"]=1
    ["ECS_AGENT_LABELS"]=1                       ["ECS_AGENT_APPARMOR_PROFILE"]=1
)

# Common functions
# ---------------------------------------------------------------------------------------

help() {
  echo "USAGE: ${progname} [--mode=[brief|enable-debug]]"
  echo "       ${progname} --help"
  echo ""
  echo "OPTIONS:"
  echo "     --mode  Sets the desired mode of the script. For more information,"
  echo "             see the MODES section."
  echo "     --help  Show this help message."
  echo ""
  echo "MODES:"
  echo "     brief         Gathers basic operating system, Docker daemon, and Amazon"
  echo "                   ECS Container Agent logs. This is the default mode."
  echo "     enable-debug  Enables debug mode for the Docker daemon and the Amazon"
  echo "                   ECS Container Agent. Only supported on Systemd init systems"
  echo "                   and Amazon Linux."
}

parse_options() {
  local count="$#"

  progname="$0"

  for i in $(seq "$count"); do
    eval arg=\$"$i"
    # shellcheck disable=SC2154
    param="$(echo "$arg" | awk -F '=' '{print $1}' | sed -e 's|--||')"
    val="$(echo "$arg" | awk -F '=' '{print $2}')"

    case "${param}" in
      mode)
        eval "$param"="${val}"
        ;;
      help)
        help && exit 0
        ;;
      *)
        echo "Parameter not found: '$param'"
        help && exit 1
        ;;
    esac
  done
}

ok() {
  echo "ok"
}

info() {
  echo "$*"
}

try() {
  local action=$*
  echo -n "Trying to $action ... "
}

warning() {
  local reason=$*
  echo "warning: $reason"
}

failed() {
  local reason=$*
  echo "failed: $reason"
}

die() {
  echo "ERROR: $*"
  exit 1
}

is_root() {
  try "check if the script is running as root"

  if [[ "$(id -u)" != "0" ]]; then
    die "this script must be run as root!"

  fi

  ok
}

cleanup() {
  rm -rf "$collectdir" >/dev/null 2>&1
  rm -f "$curdir"/collect.tgz
}

init() {
  is_root
  try_set_instance_collectdir
  get_init_type
  get_pkgtype
  get_jsonformatter
}

collect_brief() {
  init
  is_diskfull
  get_common_logs
  get_kernel_logs
  get_mounts_info
  get_selinux_info
  get_iptables_info
  get_pkglist
  get_system_services
  get_docker_info
  get_docker_containers_info
  get_docker_logs
  get_docker_systemd_config
  get_docker_sysconfig
  get_docker_daemon_json
  get_ecs_agent_logs
  get_ecs_agent_info
  get_open_files
  get_os_release
  get_uname_info
  get_dmidecode_info
  get_lsmod_info
  get_cgroupv2_events
  get_systemd_slice_info
  get_veth_info
  get_gpu_info
}

enable_debug() {
  is_root
  get_init_type
  enable_docker_debug
  enable_ecs_agent_debug
}

# Routines
# ---------------------------------------------------------------------------------------

# uname gets basic system and kernel information.
get_uname_info() {
  try "get uname kernel info"

  mkdir -p "$info_system"
  uname -a > "$info_system"/uname.txt

  ok
}

# dmidecode is a tool sometimes installed on VMs that provides detailed
# information about the VM hypervisor, underlying hardware, and system.
get_dmidecode_info() {
  try "get dmidecode info"

  if command -v dmidecode &>/dev/null; then
    mkdir -p "$info_system"
    dmidecode > "$info_system"/dmidecode.txt
  fi

  ok
}

# lsmod lists loadable kernel modules.
get_lsmod_info() {
  try "get lsmod info"

  if command -v lsmod &>/dev/null; then
    mkdir -p "$info_system"
    lsmod > "$info_system"/lsmod.txt
  fi

  ok
}

get_init_type() {
  try "collect system information"

  case "$(cat /proc/1/comm)" in
    systemd)
      init_type="systemd"
    ;;
    *)
      init_type="other"
    ;;
  esac

  ok
}

get_pkgtype() {
  if [[ -n "$(command -v rpm)" ]]; then
    pkgtype="rpm"
  elif [[ -n "$(command -v dpkg)" ]]; then
    pkgtype="dpkg"
  else
    pkgtype="unknown"
  fi
}

get_jsonformatter(){
  if [[ -n "$(command -v python)" ]]; then
    jsonformatter="python -mjson.tool"
  elif [[ -n "$(command -v jq)" ]]; then
    jsonformatter="jq"
  else
    jsonformatter=""
  fi
}

try_set_instance_collectdir() {
  try "resolve instance-id"

  if [ -f /var/lib/amazon/ssm/registration ]; then
    info "SSM managed instance detected, getting managed instance id"
    if command -v jq > /dev/null; then
      instance_id=$(jq -r ".ManagedInstanceID" < /var/lib/amazon/ssm/registration)
    fi
  fi

  if test -z "$instance_id" && command -v curl > /dev/null; then
    info "getting instance id from ec2 metadata endpoint"
    imds="http://169.254.169.254/latest"
    token=$(curl -sS --retry 3 -X PUT "${imds}/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
    instance_id=$(curl -sS --retry 3 -H "X-aws-ec2-metadata-token: $token" "${imds}/meta-data/instance-id" 2>/dev/null)
  fi

  if [ -n "$instance_id" ]; then
    # Put logs into a directory for this instance.
    info_system="${collectdir}/${instance_id}"
    # And in a pack that includes the instance id in its name.
    pack_name="collect-${instance_id}"
    mkdir -p "${info_system}"
    echo "$instance_id" > "$info_system"/instance-id.txt
  else
    warning "unable to get instance id"
    return 1
  fi

  ok
}

pack() {
  try "archive gathered log information"

  local tar_bin
  tar_bin="$(command -v tar 2>/dev/null)"
  [ -z "${tar_bin}" ] && warning "TAR archiver not found, please install a TAR archiver to create the collection archive. You can still view the logs in the collect folder."

  cd "$curdir" || { echo "cd failed."; exit 1; }

  ${tar_bin} -cvzf "$curdir/$pack_name-$datetime".tgz "$collectdir" > /dev/null 2>&1

  ok
}

is_diskfull() {
  try "check disk space usage"

  threshold=70
  i=2
  result=$(df -kh | grep -ve "Filesystem" -ve "loop" | awk '{ print $5 }' | sed 's/%//g')
  exceeded=0

  for percent in ${result}; do
    if [[ "${percent}" -gt "${threshold}" ]]; then
      partition=$(df -kh | head -$i | tail -1| awk '{print $1}')
      echo
      warning "${partition} is ${percent}% full, please ensure adequate disk space to collect and store the log files."
      : $((exceeded++))
    fi
    i=$((i+1))
  done

  if [ "$exceeded" -gt 0 ]; then
    return 1
  else
    ok
  fi
}

get_mounts_info() {
  try "get mount points and volume information"

  mkdir -p "$info_system"
  mount > "$info_system"/mounts.txt
  echo "" >> "$info_system"/mounts.txt
  df -h >> "$info_system"/mounts.txt

  if command -v lvdisplay > /dev/null; then
    lvdisplay > "$info_system"/lvdisplay.txt
    vgdisplay > "$info_system"/vgdisplay.txt
    pvdisplay > "$info_system"/pvdisplay.txt
  fi

  ok
}

get_veth_info() {
  try "get veth info"

  if command -v brctl >/dev/null; then
    brctl show > "$info_system"/brctlshow.txt
  fi

  if command -v ip >/dev/null; then
    ip addr show > "$info_system"/ipaddrshow.txt
  fi

  ok
}

get_selinux_info() {
  try "check SELinux status"

  enforced="$(getenforce 2>/dev/null)"

  { [ "${pkgtype}" != "rpm" ] || [ -z "${enforced}" ]; } \
    && info "not installed" \
    && return

  mkdir -p "$info_system"
  echo -e "SELinux mode:\\n    ${enforced}" >  "$info_system"/selinux.txt

  ok
}

get_iptables_info() {
  try "get iptables list"

  mkdir -p "$info_system"
  iptables -nvL -t filter > "$info_system"/iptables-filter.txt
  iptables -nvL -t nat  > "$info_system"/iptables-nat.txt

  ok
}

get_open_files() {
  try "get open files list"

  mkdir -p "$info_system"
  for d in /proc/*/fd; do echo "$d"; find "$d" -maxdepth 1 | wc -l; done > "$info_system"/open-file-counts.txt
  ls -l /proc/*/fd > "$info_system"/open-file-details.txt

  ok
}

get_common_logs() {
  try "collect common operating system logs"

  mkdir -p "$info_system"
  if command -v journalctl >/dev/null; then
      journalctl > "${info_system}"/system.log
  fi

  dstdir="${info_system}/var_log"
  mkdir -p "$dstdir"

  for entry in syslog messages; do
    [ -e "/var/log/${entry}" ] && cp -f /var/log/${entry} "$dstdir"/
  done

  ok
}

get_kernel_logs() {
  try "collect kernel logs"

  dstdir="${info_system}/kernel"
  mkdir -p "$dstdir"
  if [ -e "/var/log/dmesg" ]; then
    cp -f /var/log/dmesg "$dstdir/dmesg.boot"
  fi
  dmesg > "$dstdir/dmesg.current"
  dmesg --ctime > "$dstdir/dmesg.human.current"
  ok
}

get_docker_logs() {
  try "collect Docker and containerd daemon logs"

  dstdir="${info_system}/docker_log"
  mkdir -p "$dstdir"
  case "${init_type}" in
    systemd)
      journalctl -u docker > "${dstdir}"/docker
      journalctl -u containerd > "${info_system}"/containerd.log
      ;;
    other)
      for entry in docker upstart/docker; do
        if [[ -e "/var/log/${entry}" ]]; then
          cp -f /var/log/"${entry}" "${dstdir}"/docker
        fi
      done
      ;;
    *)
      warning "the current operating system is not supported."
      return 1
      ;;
  esac

  ok
}

get_ecs_agent_logs() {
  try "collect Amazon ECS Container Agent logs"

  dstdir="${info_system}/ecs_agent_logs"

  if [ ! -d /var/log/ecs ]; then
    failed "ECS log directory does not exist"
    return 1
  fi

  mkdir -p "$dstdir"

  cp -f -r /var/log/ecs/* "$dstdir"/

  for file in "$dstdir"/*; do
    if [[ -f "$file" ]]; then

      for var in "${vars_to_redact[@]}"; do
        if grep --quiet "${var}=" "$file"; then
          sed -i "s/${var}=.*/${var}={REDACTED}\"/g" "$file"
        fi
      done

    fi
  done

  ok
}

get_pkglist() {
  try "detect installed packages"

  mkdir -p "$info_system"
  case "${pkgtype}" in
    rpm)
      rpm -qa >"$info_system"/pkglist.txt 2>&1
      ;;
    dpkg)
      dpkg --list > "$info_system"/pkglist.txt 2>&1
      ;;
    *)
      warning "unknown package type."
      return 1
      ;;
  esac

  ok
}

get_system_services() {
  try "detect active system services list"

  mkdir -p "$info_system"
  case "${init_type}" in
    systemd)
      systemctl list-units > "$info_system"/services.txt 2>&1
      ;;
    other)
      service --status-all >> "$info_system"/services.txt 2>&1
      ;;
    *)
      warning "unable to determine active services."
      return 1
      ;;
  esac

  top -b -n 1 > "$info_system"/top.txt 2>&1
  ps fauxwww > "$info_system"/ps.txt 2>&1
  netstat -plant > "$info_system"/netstat.txt 2>&1

  ok
}

get_docker_info() {
  try "gather Docker daemon information"

  mkdir -p "$info_system"/docker

  if pgrep dockerd > /dev/null ; then

    timeout 20 docker info > "$info_system"/docker/docker-info.txt 2>&1 || echo "Timed out, ignoring \"docker info output \" "
    timeout 20 docker ps --all --no-trunc > "$info_system"/docker/docker-ps.txt 2>&1 || echo "Timed out, ignoring \"docker ps --all --no-trunc output \" "
    timeout 20 docker images > "$info_system"/docker/docker-images.txt 2>&1 || echo "Timed out, ignoring \"docker images output \" "
    timeout 20 docker version > "$info_system"/docker/docker-version.txt 2>&1 || echo "Timed out, ignoring \"docker version output \" "
    timeout 60 docker stats --all --no-trunc --no-stream > "$info_system"/docker/docker-stats.txt 2>&1 || echo "Timed out, ignoring \"docker stats\" output"

    ok
  else
    warning "the Docker daemon is not running." | tee "$info_system"/docker/docker-not-running.txt
  fi
}

get_ecs_agent_info() {
  try "collect Amazon ECS Container Agent state and config"

  mkdir -p "$info_system"/ecs-agent
  if [ -e /var/lib/ecs/data/ecs_agent_data.json ]; then
    cp -f /var/lib/ecs/data/ecs_agent_data.json "$info_system"/ecs-agent/ecs_agent_data.txt 2>&1
    if [ -n "$jsonformatter" ]; then
      cat "$info_system"/ecs-agent/ecs_agent_data.txt | $jsonformatter > "$info_system"/ecs-agent/ecs_agent_data_tmp.txt
      mv "$info_system"/ecs-agent/ecs_agent_data_tmp.txt "$info_system"/ecs-agent/ecs_agent_data.txt
    fi
  fi

  if [ -e /etc/ecs/ecs.config ]; then
    source_file="/etc/ecs/ecs.config"

    line_is_safe=0
    while IFS= read -r line; do
      if [[ "$line" == *"="* ]]; then
        var_name="${line%%=*}"
        if [[ -n "${ecs_config_allowlist[$var_name]+x}" ]]; then
          line_is_safe=1
        else
          line_is_safe=0
          echo "$var_name={REDACTED}" >> "$info_system"/ecs-agent/ecs.config
        fi
      fi

      if [[ $line_is_safe -eq 1 ]]; then 
        echo "$line" >> "$info_system"/ecs-agent/ecs.config
      fi
    done < "$source_file"
  fi
  ok

  try "collect Amazon ECS Container Agent engine data"

  if pgrep agent > /dev/null ; then
    if command -v curl >/dev/null; then
      if curl --max-time 3 -s http://localhost:51678/v1/tasks > "$info_system"/ecs-agent/agent-running-info.txt 2>&1; then
        if [ -n "$jsonformatter" ]; then
          cat "$info_system"/ecs-agent/agent-running-info.txt | $jsonformatter > "$info_system"/ecs-agent/agent-running-info-tmp.txt
          mv "$info_system"/ecs-agent/agent-running-info-tmp.txt "$info_system"/ecs-agent/agent-running-info.txt
        fi
          ok
      else
          warning "failed to get agent data"
      fi
    else
      warning "curl is unavailable for probing ECS Container Agent introspection endpoint"
    fi
  else
    warning "The Amazon ECS Container Agent is not running" | tee "$info_system"/ecs-agent/ecs-agent-not-running.txt
    return 1
  fi
}

get_docker_containers_info() {
  try "inspect all Docker containers"

  mkdir -p "$info_system"/docker

  if pgrep dockerd > /dev/null ; then
    for i in $(docker ps -a -q); do
      timeout 10 docker inspect "$i" > "$info_system"/docker/container-"$i".txt 2>&1
      if [ $? -eq 124 ]; then
        touch "$info_system"/docker/container-inspect-timed-out.txt
        failed "'docker inspect' timed out, not gathering containers"
        return 1
      fi

      env_vars=$(docker inspect --format='{{range $element := .Config.Env}}{{println $element}}{{end}}' "$i" | while IFS='=' read -r name value; do echo "$name"; done)
      for env_var in $env_vars; do
        sed -i "s/${env_var}=.*/${env_var}={REDACTED}\"/g" "$info_system"/docker/container-"$i".txt
      done
    done
  else
    warning "the Docker daemon is not running." | tee "$info_system"/docker/docker-not-running.txt
    return 1
  fi
  ok
}

get_docker_sysconfig() {
  try "collect Docker sysconfig"

  if [ -e /etc/sysconfig/docker ]; then
    mkdir -p "${info_system}"/docker
    cp /etc/sysconfig/docker "${info_system}"/docker/sysconfig-docker
    ok
  else
    info "/etc/sysconfig/docker not found"
  fi

 try "collect Docker storage sysconfig"

  if [ -e /etc/sysconfig/docker-storage ]; then
    mkdir -p "${info_system}"/docker
    cp /etc/sysconfig/docker-storage "${info_system}"/docker/sysconfig-docker-storage
    ok
  else
    info "/etc/sysconfig/docker-storage not found"
  fi
}


get_docker_daemon_json(){
  try "collect Docker daemon.json"

  if [ -e /etc/docker/daemon.json ]; then
    mkdir -p "${info_system}"/docker
    cp /etc/docker/daemon.json "${info_system}"/docker/daemon.json
    ok
  else
    info "/etc/docker/daemon.json not found"
  fi
}

get_docker_systemd_config(){

  if [[ "$init_type" != "systemd" ]]; then
    return 0
  fi

  try "collect Docker systemd unit file"

  mkdir -p "${info_system}"/docker
  if systemctl cat docker.service > "${info_system}"/docker/docker.service 2>/dev/null; then
   ok
  else
    rm -f "$info_system/docker/docker.service"
    warning "docker.service not found"
  fi

  try "collect containerd systemd unit file"
  if systemctl cat containerd.service > "${info_system}"/docker/containerd.service 2>/dev/null; then
   ok
  else
    rm -f "$info_system/docker/containerd.service"
    warning "containerd.service not found"
  fi
}

get_os_release(){
  try "collect /etc/os-release"

  if [ -f /etc/os-release ]; then
    cat /etc/os-release > "${info_system}"/os-release
    ok
  else
    info "/etc/os-release not found"
  fi
}

get_cgroupv2_events(){
  # cgroup v2 is only supported on systemd systems
  if [[ "$init_type" != "systemd" ]]; then
    return 0
  fi
  # this file will only exist on systems with cgroup v2 enabled
  if [ ! -f /sys/fs/cgroup/cgroup.controllers ]; then
    return 0
  fi
  try "collect cgroupv2 events"

  local outfile="${info_system}"/cgroupv2.events
  touch $outfile
  # find cgroup memory event files for all ecs tasks with task resource limits and all
  # docker containers running on the system.
  for eventfile in $(find /sys/fs/cgroup/ -type f -name "memory*events" | grep -e "docker-" -e "ecstask"); do
    echo "$eventfile" >> $outfile
    cat $eventfile >> $outfile
    echo "" >> $outfile
  done
  ok
}

get_systemd_slice_info(){
  if [[ "$init_type" != "systemd" ]]; then
    return 0
  fi
  try "collect systemd slice info"

  # system.slice will exist on all systemd systems:
  local outfile="${info_system}"/system.slice
  touch $outfile
  systemctl status system.slice >$outfile
  # ecstasks.slice will only exist if we're using the systemd cgroup driver and cgroups v2:
  if systemctl status ecstasks.slice &>/dev/null; then
    local outfile="${info_system}"/ecstasks.slice
    touch $outfile
    systemctl status ecstasks.slice >$outfile
  fi
  ok
}

enable_docker_debug() {
  try "enable debug mode for the Docker daemon"

  if [ -e /etc/sysconfig/docker ] && grep -q "^\\s*OPTIONS=\"-D" /etc/sysconfig/docker; then
    info "Debug mode is already enabled."
  else

    if [ -e /etc/sysconfig/docker ]; then
      case "${init_type}" in
        systemd)
          sed -i 's/^OPTIONS="\(.*\)/OPTIONS="-D \1/g' /etc/sysconfig/docker
          ok

          try "restart Docker daemon to enable debug mode"
          systemctl restart docker.service
          ok
          ;;
        *)
          echo "OPTIONS=\"-D \$OPTIONS\"" >> /etc/sysconfig/docker

          try "restart Docker daemon to enable debug mode"
          service docker restart
          ok

        esac

    else
      warning "the current operating system is not supported."
    fi
  fi
}

enable_ecs_agent_debug() {
  try "enable debug mode for the Amazon ECS Container Agent"

  if [ -e /etc/ecs/ecs.config ] &&  grep -q "^\\s*ECS_LOGLEVEL=debug" /etc/ecs/ecs.config; then
    info "Debug mode is already enabled."
  else

    case "${init_type}" in
    systemd)
      if [ ! -d /etc/ecs ]; then
        mkdir /etc/ecs
      fi

      echo "ECS_LOGLEVEL=debug" >> /etc/ecs/ecs.config
      ok

      try "restart the Amazon ECS Container Agent to enable debug mode"
      systemctl restart ecs
      ok
      ;;
    *)
      if rpm -q --quiet ecs-init; then
        if [ ! -d /etc/ecs ]; then
          mkdir /etc/ecs
        fi

        echo "ECS_LOGLEVEL=debug" >> /etc/ecs/ecs.config
        ok

        try "restart the Amazon ECS Container Agent to enable debug mode"
        stop ecs; start ecs
        ok
      else
        warning "the current operating system is not supported."
      fi
      ;;
    esac
  fi
}

# nvidia-smi is a tool available on GPU based AMIs provides detailed
# information about the GPU present on the VM.
get_gpu_info() {
  try "get gpu info"

  if command -v nvidia-smi &>/dev/null; then
    mkdir -p "$info_system"/gpu
    nvidia-smi -L > "$info_system"/gpu/gpu-list.txt
    nvidia-smi -q > "$info_system"/gpu/gpu-info.txt
  fi

  # get open kernel module version
  if [ -d /var/lib/dkms-archive/nvidia-open ]; then
    ls /var/lib/dkms-archive/nvidia-open > "$info_system"/gpu/gpu-open-module.txt
  fi

  if command -v modinfo nvidia &>/dev/null; then
    modinfo nvidia > "$info_system"/gpu/gpu-installed-kmod.txt
  fi

  ok
}
# --------------------------------------------------------------------------------------------

parse_options "$@"

case "${mode}" in
  brief)
    cleanup
    collect_brief
    pack
    ;;
  enable-debug)
    enable_debug
    ;;
  *)
    help && exit 1
    ;;
esac
