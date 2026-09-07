#!/usr/bin/env bash
# Install the CI-pinned PowerShell runtime after verifying its official checksum.
set -euo pipefail
version="${1:-7.4.7}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Expected a stable PowerShell version.' >&2; exit 2; }
case "$(uname -m)" in
  x86_64) arch=x64; checksum=cfd57927b7a0d9f2da400471ea8dadc3ceb52f5e4a4a9a51c20495b4071f055a ;;
  aarch64|arm64) arch=arm64; checksum=e5d34d4777c4d8841eade59dfdb6a8ceb0bb64b690863e4bf976eb698021f446 ;;
  *) echo 'PowerShell container supports x86-64 and ARM64.' >&2; exit 2 ;;
esac
install_deps_arch() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm \
    git \
    icu \
    openssl \
    curl \
    ca-certificates \
    tar \
    gzip \
    which \
    less \
    sudo \
    base-devel
}

install_deps_debian() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    tar \
    gzip \
    less \
    sudo \
    locales \
    openssl

  # ICU / OpenSSL SONAME packages differ across Ubuntu releases (and t64 transition).
  local icu_pkg ssl_pkg
  icu_pkg="$(apt-cache search --names-only '^libicu[0-9]+t64$|^libicu[0-9]+$' 2>/dev/null | awk '{print $1}' | sort -V | tail -1 || true)"
  if [[ -n "${icu_pkg}" ]]; then
    apt-get install -y --no-install-recommends "${icu_pkg}"
  fi
  for ssl_pkg in libssl3t64 libssl3; do
    if apt-cache show "${ssl_pkg}" >/dev/null 2>&1; then
      apt-get install -y --no-install-recommends "${ssl_pkg}"
      break
    fi
  done

  rm -rf /var/lib/apt/lists/*
}

if [[ -f /etc/arch-release ]]; then
  install_deps_arch
elif [[ -f /etc/debian_version ]]; then
  install_deps_debian
else
  echo "Unsupported distro for install-pwsh-linux.sh (need Arch or Debian/Ubuntu)" >&2
  exit 1
fi


if [[ "$version" != 7.4.7 ]]; then
  # Explicit CI overrides use the matching release's checksum manifest.
  checksum=$(curl --fail --show-error --location --retry 3 \
    "https://github.com/PowerShell/PowerShell/releases/download/v${version}/hashes.sha256" |
    awk -v file="powershell-${version}-linux-${arch}.tar.gz" '$2 == "*" file || $2 == file { print $1 }')
  [[ "$checksum" =~ ^[a-fA-F0-9]{64}$ ]] || { echo 'Missing release checksum.' >&2; exit 2; }
fi
archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
curl --fail --show-error --location --retry 3 --output "$archive" \
  "https://github.com/PowerShell/PowerShell/releases/download/v${version}/powershell-${version}-linux-${arch}.tar.gz"
printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check -
install -d /opt/microsoft/powershell/7
tar -xzf "$archive" -C /opt/microsoft/powershell/7
chmod a+x /opt/microsoft/powershell/7/pwsh
ln -sfn /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh
# PowerShell expands these variables, not Bash.
# shellcheck disable=SC2016
pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
