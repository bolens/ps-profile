# ===============================================
# 50-azure.ps1
# Azure CLI helpers (guarded)
# ===============================================

<#
Register Azure CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Azure execute - run az with arguments
if (-not (Test-Path Function:az -ErrorAction SilentlyContinue)) { Set-Item -Path Function:az -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command az -ErrorAction SilentlyContinue) { az @a } else { Write-Warning 'az not found' } } -Force | Out-Null }

# Azure Developer CLI - Azure development tools
if (-not (Test-Path Function:azd -ErrorAction SilentlyContinue)) { Set-Item -Path Function:azd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command azd -ErrorAction SilentlyContinue) { azd @a } else { Write-Warning 'azd not found' } } -Force | Out-Null }

# Azure login - authenticate with Azure CLI
if (-not (Test-Path Function:az-login -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:az-login -Value { if (Test-CachedCommand az) { az login } else { Write-Warning 'Azure CLI (az) not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:az-login -Value { if (Get-Command az -ErrorAction SilentlyContinue) { az login } else { Write-Warning 'Azure CLI (az) not found' } } -Force | Out-Null
    }
}

# Azure Developer CLI up - provision and deploy
if (-not (Test-Path Function:azd-up -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:azd-up -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand azd) { azd up @a } else { Write-Warning 'Azure Developer CLI (azd) not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:azd-up -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command azd -ErrorAction SilentlyContinue) { azd up @a } else { Write-Warning 'Azure Developer CLI (azd) not found' } } -Force | Out-Null
    }
}




















