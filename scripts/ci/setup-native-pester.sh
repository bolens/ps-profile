#!/usr/bin/env bash
# Install test dependencies inside the job container.
set -euo pipefail
umask 077
tools=/tmp/native-pester-tools
home=/tmp/native-pester-home
download() {
    curl --silent --show-error --fail --location --proto '=https' --proto-redir '=https' \
        --tlsv1.2 --connect-timeout 30 --max-time 600 --retry 2 --retry-max-time 600 \
        --max-filesize 268435456 --output "$1" "$2"
}

test ! -e "$tools"
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git libatomic1 libicu74 libssl3t64 openssh-client python3 unzip xz-utils zstd
mkdir -p "$tools/node" "$tools/pwsh" "$tools/modules/Pester/5.7.1" "$home"
download "$tools/pwsh.tar.gz" https://github.com/PowerShell/PowerShell/releases/download/v7.6.10/powershell-7.6.10-linux-x64.tar.gz
printf '%s  %s\n' e261cabc91c78a9afe8d1e5f24731ab0d38204735ab2ec94b0af55102652e10d "$tools/pwsh.tar.gz" | sha256sum --check --strict
tar -xzf "$tools/pwsh.tar.gz" -C "$tools/pwsh"
chmod u+x "$tools/pwsh/pwsh"
download "$tools/pester.zip" https://cdn.powershellgallery.com/packages/pester.5.7.1.nupkg
printf '%s  %s\n' 4a27904c6814a5fbe4758f8e49861f6a1994aee77b71165a5c43c0371ba6c580 "$tools/pester.zip" | sha256sum --check --strict
unzip -q "$tools/pester.zip" -d "$tools/modules/Pester/5.7.1"
download "$tools/node.tar.xz" https://nodejs.org/dist/v26.13.1/node-v26.13.1-linux-x64.tar.xz
printf '%s  %s\n' 5c063e46bab0fbc1c17cc445d7ff129cbdcd0471be6ed83b6ab864f8143bc864 "$tools/node.tar.xz" | sha256sum --check --strict
tar -xJf "$tools/node.tar.xz" -C "$tools/node" --strip-components=1
test "$("$tools/node/bin/node" --version)" = v26.13.1
# PowerShell variables are deliberately literal to Bash.
# shellcheck disable=SC2016
HOME="$home" PSModulePath="$tools/modules:$tools/pwsh/Modules" "$tools/pwsh/pwsh" -NoLogo -NoProfile -NonInteractive -Command 'if ($PSVersionTable.PSVersion.ToString() -ne "7.6.10") { throw "Wrong PowerShell runtime" }; Import-Module Pester -RequiredVersion 5.7.1 -ErrorAction Stop; if ((Get-Module Pester).Version.ToString() -ne "5.7.1") { throw "Wrong Pester" }'
