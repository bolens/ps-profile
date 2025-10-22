# ===============================================
# 35-rustup.ps1
# Rustup toolchain helpers (guarded)
# ===============================================

<#
Register Rustup helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Rustup execute - run rustup with arguments
if (-not (Test-Path Function:rustup -ErrorAction SilentlyContinue)) { Set-Item -Path Function:rustup -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command rustup -ErrorAction SilentlyContinue) { rustup @a } else { Write-Warning 'rustup not found' } } -Force | Out-Null }

# Rustup update - update Rust toolchain
if (-not (Test-Path Function:rustup-update -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:rustup-update -Value { if (Test-CachedCommand rustup) { rustup update } else { Write-Warning 'rustup not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:rustup-update -Value { if (Get-Command rustup -ErrorAction SilentlyContinue) { rustup update } else { Write-Warning 'rustup not found' } } -Force | Out-Null
  }
}

# Rustup install - install Rust toolchains
if (-not (Test-Path Function:rustup-install -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:rustup-install -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand rustup) { rustup install @a } else { Write-Warning 'rustup not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:rustup-install -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command rustup -ErrorAction SilentlyContinue) { rustup install @a } else { Write-Warning 'rustup not found' } } -Force | Out-Null
  }
}


