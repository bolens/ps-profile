# ===============================================
# 50-azure.ps1
# Azure CLI helpers (guarded)
# ===============================================

<#
Register Azure CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Azure execute - run az with arguments
if (-not (Test-Path Function:az -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:az -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand az) { az @a } else { Write-Warning 'az not found' } } -Force | Out-Null
}

# Azure Developer CLI - Azure development tools
if (-not (Test-Path Function:azd -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:azd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand azd) { azd @a } else { Write-Warning 'azd not found' } } -Force | Out-Null
}

# Azure login - authenticate with Azure CLI
if (-not (Test-Path Function:az-login -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:az-login -Value { if (Test-HasCommand az) { az login } else { Write-Warning 'Azure CLI (az) not found' } } -Force | Out-Null
}

# Azure Developer CLI up - provision and deploy
if (-not (Test-Path Function:azd-up -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:azd-up -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand azd) { azd up @a } else { Write-Warning 'Azure Developer CLI (azd) not found' } } -Force | Out-Null
}
