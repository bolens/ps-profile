# ===============================================
# 51-gcloud.ps1
# Google Cloud CLI helpers (guarded)
# ===============================================

<#
Register Google Cloud CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Google Cloud execute - run gcloud with arguments
if (-not (Test-Path Function:gcloud -ErrorAction SilentlyContinue)) { Set-Item -Path Function:gcloud -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command gcloud -ErrorAction SilentlyContinue) { gcloud @a } else { Write-Warning 'gcloud not found' } } -Force | Out-Null }

# Google Cloud auth - manage authentication
if (-not (Test-Path Function:gcloud-auth -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:gcloud-auth -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand gcloud) { gcloud auth @a } else { Write-Warning 'Google Cloud CLI (gcloud) not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:gcloud-auth -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command gcloud -ErrorAction SilentlyContinue) { gcloud auth @a } else { Write-Warning 'Google Cloud CLI (gcloud) not found' } } -Force | Out-Null
    }
}

# Google Cloud config - manage configuration
if (-not (Test-Path Function:gcloud-config -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:gcloud-config -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand gcloud) { gcloud config @a } else { Write-Warning 'Google Cloud CLI (gcloud) not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:gcloud-config -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command gcloud -ErrorAction SilentlyContinue) { gcloud config @a } else { Write-Warning 'Google Cloud CLI (gcloud) not found' } } -Force | Out-Null
    }
}

# Google Cloud projects - manage GCP projects
if (-not (Test-Path Function:gcloud-projects -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:gcloud-projects -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand gcloud) { gcloud projects @a } else { Write-Warning 'Google Cloud CLI (gcloud) not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:gcloud-projects -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command gcloud -ErrorAction SilentlyContinue) { gcloud projects @a } else { Write-Warning 'Google Cloud CLI (gcloud) not found' } } -Force | Out-Null
    }
}

























