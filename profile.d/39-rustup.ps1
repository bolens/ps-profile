# ===============================================
# 39-rustup.ps1
# Rustup toolchain helpers (guarded)
# ===============================================

<#
Register Rustup helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Rustup execute - run rustup with arguments
if (-not (Test-Path Function:rustup -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rustup -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand rustup) { rustup @a } else { Write-Warning 'rustup not found' } } -Force | Out-Null
}

# Rustup update - update Rust toolchain
if (-not (Test-Path Function:rustup-update -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rustup-update -Value { if (Test-HasCommand rustup) { rustup update } else { Write-Warning 'rustup not found' } } -Force | Out-Null
}

# Rustup install - install Rust toolchains
if (-not (Test-Path Function:rustup-install -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rustup-install -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand rustup) { rustup install @a } else { Write-Warning 'rustup not found' } } -Force | Out-Null
}
