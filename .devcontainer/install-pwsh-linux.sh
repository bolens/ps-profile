#!/usr/bin/env bash
# Install PowerShell from the official Linux x64 tarball (CI + Dev Containers).
# Usage: install-pwsh-linux.sh [version]
set -euo pipefail

pwsh_version="${1:-7.4.7}"
install_root="/opt/microsoft/powershell/$(echo "${pwsh_version}" | cut -d. -f1,2)"
tarball="powershell-${pwsh_version}-linux-x64.tar.gz"
download_url="https://github.com/PowerShell/PowerShell/releases/download/v${pwsh_version}/${tarball}"

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

mkdir -p "${install_root}"
curl -fsSL -o "/tmp/${tarball}" "${download_url}"
tar -xzf "/tmp/${tarball}" -C "${install_root}"
rm -f "/tmp/${tarball}"

# Tar extract can leave the entrypoint non-executable in some images (exit 126).
chmod a+x "${install_root}/pwsh"
find "${install_root}" -type f -name '*.so*' -exec chmod a+x {} +

# Prefer /usr/local/bin so PATH does not resolve through Arch usr-merge /usr/sbin.
ln -sfn "${install_root}/pwsh" /usr/local/bin/pwsh
ln -sfn "${install_root}/pwsh" /usr/bin/pwsh

command -v pwsh
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
