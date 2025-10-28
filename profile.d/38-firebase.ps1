# ===============================================
# 38-firebase.ps1
# Firebase CLI helpers (guarded)
# ===============================================

<#
Register Firebase helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Firebase alias - run firebase with arguments
if (-not (Test-Path Function:fb -ErrorAction SilentlyContinue)) { Set-Item -Path Function:fb -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command fb -ErrorAction SilentlyContinue) { fb @a } else { Write-Warning 'fb not found' } } -Force | Out-Null }

# Firebase deploy - deploy to Firebase hosting
if (-not (Test-Path Function:fb-deploy -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:fb-deploy -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand firebase) { firebase deploy @a } else { Write-Warning 'firebase not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:fb-deploy -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command firebase -ErrorAction SilentlyContinue) { firebase deploy @a } else { Write-Warning 'firebase not found' } } -Force | Out-Null
  }
}

# Firebase serve - start local development server
if (-not (Test-Path Function:fb-serve -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:fb-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand firebase) { firebase serve @a } else { Write-Warning 'firebase not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:fb-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command firebase -ErrorAction SilentlyContinue) { firebase serve @a } else { Write-Warning 'firebase not found' } } -Force | Out-Null
  }
}







