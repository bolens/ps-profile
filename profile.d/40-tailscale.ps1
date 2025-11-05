# ===============================================
# 40-tailscale.ps1
# Tailscale VPN helpers (guarded)
# ===============================================

<#
Register Tailscale helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Tailscale execute - run tailscale with arguments
if (-not (Test-Path Function:tailscale -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:tailscale -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand tailscale) { tailscale @a } else { Write-Warning 'tailscale not found' } } -Force | Out-Null
}

# Tailscale up - connect to Tailscale network
if (-not (Test-Path Function:ts-up -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ts-up -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand tailscale) { tailscale up @a } else { Write-Warning 'tailscale not found' } } -Force | Out-Null
}

# Tailscale down - disconnect from Tailscale network
if (-not (Test-Path Function:ts-down -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ts-down -Value { if (Test-HasCommand tailscale) { tailscale down } else { Write-Warning 'tailscale not found' } } -Force | Out-Null
}

# Tailscale status - show connection status
if (-not (Test-Path Function:ts-status -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ts-status -Value { if (Test-HasCommand tailscale) { tailscale status } else { Write-Warning 'tailscale not found' } } -Force | Out-Null
}
