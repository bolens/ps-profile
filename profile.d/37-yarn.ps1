# ===============================================
# 37-yarn.ps1
# Yarn package manager helpers (guarded)
# ===============================================

<#
Register Yarn helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Yarn execute - run yarn with arguments
if (-not (Test-Path Function:yarn -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:yarn -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand yarn) { yarn @a } else { Write-Warning 'yarn not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:yarn -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command yarn -ErrorAction SilentlyContinue)) { yarn @a } else { Write-Warning 'yarn not found' } } -Force | Out-Null
  }
}

# Yarn add - add packages to dependencies
if (-not (Test-Path Function:yarn-add -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:yarn-add -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand yarn) { yarn add @a } else { Write-Warning 'yarn not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:yarn-add -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command yarn -ErrorAction SilentlyContinue)) { yarn add @a } else { Write-Warning 'yarn not found' } } -Force | Out-Null
  }
}

# Yarn install - install project dependencies
if (-not (Test-Path Function:yarn-install -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:yarn-install -Value { if (Test-CachedCommand yarn) { yarn install } else { Write-Warning 'yarn not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:yarn-install -Value { if ($null -ne (Get-Command yarn -ErrorAction SilentlyContinue)) { yarn install } else { Write-Warning 'yarn not found' } } -Force | Out-Null
  }
}
