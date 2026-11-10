#!/usr/bin/env bash
#
# Installs the workshop prerequisites on macOS and Linux:
# Docker, kubectl, kind, cloud-provider-kind and Helm.
#
# Tools already on your PATH are skipped. A failure in one tool doesn't
# stop the others: every failure is listed at the end, with the reason.
#
# Usage: ./install.sh, or:
#   curl -fsSL https://raw.githubusercontent.com/latitudesh/managed-k8s-workshop/main/install.sh | bash
# Then:  ./check.sh

# No `set -e`: we want to try every tool and report all failures at the end.
set -u

FAILED=()
INSTALLED=()
SKIPPED=()
NOTES=()

info() { printf '\n==> %s\n' "$*"; }
ok() { printf '    ✓ %s\n' "$*"; }
err() { printf '    ✗ %s\n' "$*"; }

# fail <tool> <reason>: records a failure and returns 1.
fail() {
  FAILED+=("$1: $2")
  err "$1: $2"
  return 1
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

case "$(uname -s)" in
  Darwin) OS=darwin ;;
  Linux) OS=linux ;;
  *)
    echo "Unsupported OS: $(uname -s). This script supports macOS and Linux only." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64 | amd64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *)
    echo "Unsupported CPU architecture: $(uname -m). This script supports amd64 and arm64 only." >&2
    exit 1
    ;;
esac

HAS_BREW=false
if [ "$OS" = darwin ] && command -v brew >/dev/null 2>&1; then
  HAS_BREW=true
fi

# Root runs commands directly; everyone else goes through sudo.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO="missing"
fi

BIN_DIR=/usr/local/bin
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# need <tool> <command>...: fails <tool> if any of the commands is missing.
need() {
  local tool="$1"
  shift
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      fail "$tool" "'$cmd' is not installed, and it's needed to download $tool. Install '$cmd' with your package manager and run this script again."
      return 1
    fi
  done
}

# need_sudo <tool>: fails <tool> if we can't write to system paths.
need_sudo() {
  if [ "$SUDO" = missing ]; then
    fail "$1" "installing to $BIN_DIR needs root, and 'sudo' is not installed. Run this script as root, or install sudo."
    return 1
  fi
}

# download <tool> <url> <dest>: downloads a file, or fails <tool> with the URL and curl's error.
download() {
  local tool="$1" url="$2" dest="$3" out
  if ! out="$(curl -fsSL --retry 3 -o "$dest" "$url" 2>&1)"; then
    fail "$tool" "download failed from $url ($(printf '%s\n' "$out" | tail -n 1)). Check your internet connection, proxy or VPN."
    return 1
  fi
}

# latest_github_tag <owner/repo>: prints the latest release tag, like v0.33.0.
# Follows the releases/latest redirect, so it doesn't hit the GitHub API rate limit.
# Runs inside $(...), so it can't call fail: the caller does.
latest_github_tag() {
  local url tag
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" 2>/dev/null)"
  tag="${url##*/}"
  case "$tag" in
    v[0-9]*) printf '%s\n' "$tag" ;;
    *) return 1 ;;
  esac
}

# latest_tag_failed <tool> <owner/repo>
latest_tag_failed() {
  fail "$1" "couldn't find the latest release at https://github.com/$2/releases/latest. Check your internet connection, proxy or VPN."
}

# install_bin <tool> <file>: copies a binary into BIN_DIR.
install_bin() {
  local tool="$1" file="$2" out
  need_sudo "$tool" || return 1
  $SUDO mkdir -p "$BIN_DIR" 2>/dev/null
  if ! out="$($SUDO install -m 0755 "$file" "$BIN_DIR/$tool" 2>&1)"; then
    fail "$tool" "couldn't copy the binary to $BIN_DIR/$tool (${out:-no error output})."
    return 1
  fi
}

# brew_install <tool> <brew args>...: installs with Homebrew.
brew_install() {
  local tool="$1"
  shift
  if ! brew install "$@"; then
    fail "$tool" "'brew install $*' failed. Read the Homebrew output above for the reason, then run this script again."
    return 1
  fi
}

# apt_busy: true while another process holds the apt/dpkg locks.
apt_busy() {
  if command -v fuser >/dev/null 2>&1; then
    $SUDO fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1
  else
    pgrep -x 'apt|apt-get|dpkg' >/dev/null 2>&1
  fi
}

# wait_for_apt <tool>: on a freshly booted machine, cloud-init and automatic updates
# run apt for several minutes. Wait for them instead of failing.
wait_for_apt() {
  command -v apt-get >/dev/null 2>&1 || return 0
  if command -v cloud-init >/dev/null 2>&1 && cloud-init status 2>/dev/null | grep -q running; then
    echo "    cloud-init is still setting up this machine. Waiting for it to finish..."
    if command -v timeout >/dev/null 2>&1; then
      timeout 900 cloud-init status --wait >/dev/null 2>&1
    else
      cloud-init status --wait >/dev/null 2>&1
    fi
  fi
  local waited=0
  while apt_busy; do
    if [ "$waited" -eq 0 ]; then
      echo "    Another apt process is running (often automatic updates right after boot). Waiting for it to finish..."
    fi
    if [ "$waited" -ge 600 ]; then
      fail "$1" "another apt process has held the package lock for 10 minutes. Find it with 'ps aux | grep -E \"apt|dpkg\"', wait for it to finish, and run this script again."
      return 1
    fi
    sleep 5
    waited=$((waited + 5))
  done
}

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

install_docker() {
  if [ "$OS" = darwin ]; then
    if [ "$HAS_BREW" = false ]; then
      fail docker "Homebrew is not installed, so Docker Desktop can't be installed automatically. Install Homebrew from https://brew.sh and run this script again, or install Docker Desktop from https://docs.docker.com/desktop/setup/install/mac-install/"
      return 1
    fi
    brew_install docker --cask docker-desktop || return 1
    open -a Docker >/dev/null 2>&1 || true
    NOTES+=("Docker Desktop: open it once, accept the terms, and set at least 4 CPUs, 8 GB of RAM and 20 GB of disk in Settings > Resources.")
    return 0
  fi

  need docker curl || return 1
  if [ "$SUDO" = missing ]; then
    fail docker "the Docker install script needs root, and 'sudo' is not installed. Run this script as root, or install sudo."
    return 1
  fi

  local script="$TMP_ROOT/get-docker.sh" log="$TMP_ROOT/get-docker.log"
  download docker https://get.docker.com "$script" || return 1
  # Automatic updates can grab the apt lock again between our check and the
  # Docker script's own apt calls, so retry a couple of times on lock errors.
  local attempt
  for attempt in 1 2 3; do
    wait_for_apt docker || return 1
    $SUDO sh "$script" 2>&1 | tee "$log"
    [ "${PIPESTATUS[0]}" -eq 0 ] && break
    if ! grep -q "Could not get lock" "$log"; then
      fail docker "the official Docker install script (https://get.docker.com) failed, see its output above. It supports Ubuntu, Debian, Fedora, RHEL and CentOS; for other distros follow https://docs.docker.com/engine/install/"
      return 1
    fi
    if [ "$attempt" -eq 3 ]; then
      fail docker "another apt process kept grabbing the package lock (often automatic updates right after boot). Wait a few minutes and run this script again."
      return 1
    fi
    echo "    Another apt process grabbed the package lock. Retrying ($((attempt + 1))/3)..."
    sleep 10
  done

  if command -v systemctl >/dev/null 2>&1; then
    if ! $SUDO systemctl enable --now docker >/dev/null 2>&1; then
      NOTES+=("Docker: installed, but the service didn't start. Start it with 'sudo systemctl start docker'.")
    fi
  fi

  local user="${USER:-$(id -un)}"
  if [ "$(id -u)" -ne 0 ] && ! id -nG "$user" | grep -qw docker; then
    if $SUDO usermod -aG docker "$user"; then
      NOTES+=("Docker: you were added to the 'docker' group. Log out and back in (or run 'newgrp docker') so you can use docker without sudo.")
    else
      NOTES+=("Docker: couldn't add you to the 'docker' group. Run 'sudo usermod -aG docker \$USER', then log out and back in.")
    fi
  fi
}

install_kubectl() {
  if [ "$HAS_BREW" = true ]; then
    brew_install kubectl kubectl
    return
  fi
  need kubectl curl || return 1

  local version out
  if ! version="$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>&1)"; then
    fail kubectl "couldn't read the latest version from https://dl.k8s.io/release/stable.txt (${version}). Check your internet connection, proxy or VPN."
    return 1
  fi
  out="$TMP_ROOT/kubectl"
  download kubectl "https://dl.k8s.io/release/$version/bin/$OS/$ARCH/kubectl" "$out" || return 1
  install_bin kubectl "$out"
}

install_kind() {
  if [ "$HAS_BREW" = true ]; then
    brew_install kind kind
    return
  fi
  need kind curl || return 1

  local tag out
  tag="$(latest_github_tag kubernetes-sigs/kind)" || { latest_tag_failed kind kubernetes-sigs/kind; return 1; }
  out="$TMP_ROOT/kind"
  download kind "https://github.com/kubernetes-sigs/kind/releases/download/$tag/kind-$OS-$ARCH" "$out" || return 1
  install_bin kind "$out"
}

install_cloud_provider_kind() {
  if [ "$HAS_BREW" = true ]; then
    brew_install cloud-provider-kind cloud-provider-kind
    return
  fi
  need cloud-provider-kind curl tar || return 1

  local tag dir archive
  tag="$(latest_github_tag kubernetes-sigs/cloud-provider-kind)" || { latest_tag_failed cloud-provider-kind kubernetes-sigs/cloud-provider-kind; return 1; }
  dir="$TMP_ROOT/cloud-provider-kind"
  archive="$dir.tar.gz"
  mkdir -p "$dir"
  download cloud-provider-kind \
    "https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/$tag/cloud-provider-kind_${tag#v}_${OS}_${ARCH}.tar.gz" \
    "$archive" || return 1
  if ! tar -xzf "$archive" -C "$dir" cloud-provider-kind 2>/dev/null; then
    fail cloud-provider-kind "the downloaded archive is corrupt or doesn't contain the cloud-provider-kind binary. Run this script again."
    return 1
  fi
  install_bin cloud-provider-kind "$dir/cloud-provider-kind"
}

install_helm() {
  if [ "$HAS_BREW" = true ]; then
    brew_install helm helm
    return
  fi
  need helm curl tar || return 1

  local tag dir archive
  tag="$(latest_github_tag helm/helm)" || { latest_tag_failed helm helm/helm; return 1; }
  dir="$TMP_ROOT/helm"
  archive="$dir.tar.gz"
  mkdir -p "$dir"
  download helm "https://get.helm.sh/helm-$tag-$OS-$ARCH.tar.gz" "$archive" || return 1
  if ! tar -xzf "$archive" -C "$dir" "$OS-$ARCH/helm" 2>/dev/null; then
    fail helm "the downloaded archive is corrupt or doesn't contain the helm binary. Run this script again."
    return 1
  fi
  install_bin helm "$dir/$OS-$ARCH/helm"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# install_tool <tool> <function>: skips tools already on the PATH.
install_tool() {
  local tool="$1" fn="$2"
  info "$tool"
  if command -v "$tool" >/dev/null 2>&1; then
    ok "already installed at $(command -v "$tool"), skipping"
    SKIPPED+=("$tool")
    return
  fi
  if "$fn"; then
    ok "installed"
    INSTALLED+=("$tool")
  fi
}

# Everything runs from main, called on the last line. When piped from curl,
# bash reads the whole script before running it, so a command that reads
# stdin can't swallow the rest, and a half-downloaded script doesn't run.
main() {
  echo "Installing workshop prerequisites ($OS/$ARCH)"
  if [ "$OS" = darwin ] && [ "$HAS_BREW" = false ]; then
    echo "Homebrew not found: CLI tools will be downloaded to $BIN_DIR instead."
  fi
  if [ -n "$SUDO" ] && [ "$SUDO" != missing ] && { [ "$OS" = linux ] || [ "$HAS_BREW" = false ]; }; then
    echo "Some steps use sudo, so you may be asked for your password."
  fi

  install_tool docker install_docker
  install_tool kubectl install_kubectl
  install_tool kind install_kind
  install_tool cloud-provider-kind install_cloud_provider_kind
  install_tool helm install_helm

  echo
  echo "------------------------------------------------------------"
  [ ${#INSTALLED[@]} -gt 0 ] && echo "Installed: ${INSTALLED[*]}"
  [ ${#SKIPPED[@]} -gt 0 ] && echo "Already installed: ${SKIPPED[*]}"

  if [ ${#NOTES[@]} -gt 0 ]; then
    echo
    echo "Next steps:"
    for note in "${NOTES[@]}"; do
      echo "  - $note"
    done
  fi

  if [ ${#FAILED[@]} -gt 0 ]; then
    echo
    echo "Failed to install ${#FAILED[@]} tool(s):" >&2
    for f in "${FAILED[@]}"; do
      echo "  ✗ $f" >&2
    done
    exit 1
  fi

  echo
  echo "Done. Run check.sh to confirm every tool works."
}

main "$@"
