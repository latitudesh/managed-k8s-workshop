#!/usr/bin/env bash
#
# Checks that the workshop prerequisites are installed and able to run:
# Docker (and its daemon), kubectl, kind, cloud-provider-kind and Helm.
# Also warns if Docker has fewer resources than the workshop needs.
#
# Usage: ./check.sh, or:
#   curl -fsSL https://raw.githubusercontent.com/latitudesh/managed-k8s-workshop/main/check.sh | bash
# Exits 1 if any tool is missing or broken. Warnings don't change the exit code.

set -u

FAILED=0
WARNED=0

ok() { printf '  ✓ %-20s %s\n' "$1" "$2"; }
bad() {
  printf '  ✗ %-20s %s\n' "$1" "$2"
  FAILED=$((FAILED + 1))
}
warn() {
  printf '  ! %-20s %s\n' "$1" "$2"
  WARNED=$((WARNED + 1))
}

case "$(uname -s)" in
  Darwin) OS=darwin ;;
  Linux) OS=linux ;;
  *) OS=other ;;
esac

# first_line <text>: first non-empty line, so errors stay on one line.
first_line() { printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | head -n 1; }

# check_tool <tool> <command>...: the tool must be on the PATH and the command must succeed.
check_tool() {
  local tool="$1" out
  shift
  if ! command -v "$tool" >/dev/null 2>&1; then
    bad "$tool" "not found on your PATH. Install it, or run install.sh."
    return 1
  fi
  if ! out="$("$@" 2>&1)"; then
    bad "$tool" "found at $(command -v "$tool"), but '$*' failed: $(first_line "$out")"
    return 1
  fi
  ok "$tool" "$(first_line "$out")"
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    bad docker "not found on your PATH. Install it, or run install.sh."
    return 1
  fi

  local out
  if ! out="$(docker info --format '{{.ServerVersion}}|{{.NCPU}}|{{.MemTotal}}|{{.OperatingSystem}}' 2>&1)"; then
    case "$out" in
      *"permission denied"*)
        local user="${USER:-$(id -un)}"
        if id -nG "$user" 2>/dev/null | grep -qw docker; then
          # In the group on disk, but this shell started before the user was added.
          bad docker "permission denied: you're in the 'docker' group, but this session started before you were added. Log out and back in (or run 'newgrp docker')."
        else
          bad docker "the CLI can't reach the daemon: permission denied. Run 'sudo usermod -aG docker \$USER', then log out and back in."
        fi
        ;;
      *"Cannot connect"* | *"Is the docker daemon running"* | *"connect: no such file"* | *"error during connect"*)
        if [ "$OS" = darwin ]; then
          bad docker "the CLI is installed, but the Docker daemon isn't running. Start Docker Desktop (or OrbStack/Colima) and run this again."
        else
          bad docker "the CLI is installed, but the Docker daemon isn't running. Start it with 'sudo systemctl start docker'."
        fi
        ;;
      *)
        bad docker "'docker info' failed: $(first_line "$out")"
        ;;
    esac
    return 1
  fi

  # Some setups print warnings before the formatted line; keep the last one.
  out="$(printf '%s\n' "$out" | tail -n 1)"
  local version cpus mem os mem_gib
  IFS='|' read -r version cpus mem os <<EOF
$out
EOF
  ok docker "server $version ($os)"

  # Docker Desktop reports a bit less than what you set (8 GB shows as ~7.7 GiB),
  # so accept anything from 7.5 GiB up.
  # Docker Desktop and friends run a VM with its own limits; on Linux it's the host.
  local raise="Raise it in Docker's resource settings."
  [ "$OS" = linux ] && raise="Docker uses this machine's resources directly, so use a bigger machine."
  mem_gib="$(awk -v m="$mem" 'BEGIN { printf "%.1f", m / 1024 / 1024 / 1024 }')"
  if [ "${cpus:-0}" -lt 4 ] 2>/dev/null; then
    warn "docker cpus" "$cpus CPU(s) available, the workshop needs at least 4. $raise"
  else
    ok "docker cpus" "$cpus"
  fi
  if awk -v m="$mem" 'BEGIN { exit !(m < 7.5 * 1024 * 1024 * 1024) }'; then
    warn "docker memory" "$mem_gib GiB available, the workshop needs at least 8 GB. $raise"
  else
    ok "docker memory" "$mem_gib GiB"
  fi
}

# kind runs every node as a container, and each one watches files with inotify.
# The Linux defaults are too low for 5 nodes and break kubelet with "too many open files".
# https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
check_inotify() {
  [ "$OS" = linux ] || return 0
  local watches instances
  watches="$(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo 0)"
  instances="$(cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 0)"
  if [ "$watches" -lt 524288 ] || [ "$instances" -lt 512 ]; then
    warn inotify "limits are low (watches=$watches, instances=$instances) for 5 kind nodes. Raise them with: sudo sysctl fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=512"
  else
    ok inotify "watches=$watches, instances=$instances"
  fi
}

echo "Checking workshop prerequisites"
echo
check_docker
check_tool kubectl kubectl version --client
check_tool kind kind version
check_tool cloud-provider-kind cloud-provider-kind version
check_tool helm helm version --short
check_inotify

echo
if [ "$FAILED" -gt 0 ]; then
  echo "$FAILED check(s) failed. Fix the ✗ lines above, then run check.sh again."
  exit 1
fi
if [ "$WARNED" -gt 0 ]; then
  echo "All tools work, but read the ! warnings above before the workshop."
else
  echo "All set. Next, get the workshop files."
fi
