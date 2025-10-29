# ===============================================
# 52-helm.ps1
# Helm Kubernetes package manager helpers (guarded)
# ===============================================

<#
Register Helm helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Helm execute - run helm with arguments
if (-not (Test-Path Function:helm -ErrorAction SilentlyContinue)) { Set-Item -Path Function:helm -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command helm -ErrorAction SilentlyContinue) { helm @a } else { Write-Warning 'helm not found' } } -Force | Out-Null }

# Helm install - install Helm charts
if (-not (Test-Path Function:helm-install -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:helm-install -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand helm) { helm install @a } else { Write-Warning 'Helm not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:helm-install -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command helm -ErrorAction SilentlyContinue) { helm install @a } else { Write-Warning 'Helm not found' } } -Force | Out-Null
    }
}

# Helm upgrade - upgrade Helm releases
if (-not (Test-Path Function:helm-upgrade -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:helm-upgrade -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand helm) { helm upgrade @a } else { Write-Warning 'Helm not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:helm-upgrade -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command helm -ErrorAction SilentlyContinue) { helm upgrade @a } else { Write-Warning 'Helm not found' } } -Force | Out-Null
    }
}

# Helm list - list Helm releases
if (-not (Test-Path Function:helm-list -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:helm-list -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand helm) { helm list @a } else { Write-Warning 'Helm not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:helm-list -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command helm -ErrorAction SilentlyContinue) { helm list @a } else { Write-Warning 'Helm not found' } } -Force | Out-Null
    }
}




















