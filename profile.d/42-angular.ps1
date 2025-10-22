# ===============================================
# 42-angular.ps1
# Angular CLI helpers (guarded)
# ===============================================

<#
Register Angular helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Angular execute - run angular with arguments
if (-not (Test-Path Function:ng -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:ng -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx @angular/cli @a } elseif (Test-CachedCommand ng) { ng @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:ng -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx @angular/cli @a } elseif (Get-Command ng -ErrorAction SilentlyContinue) { ng @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
  }
}

# Angular new project - create new Angular application
if (-not (Test-Path Function:ng-new -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:ng-new -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx @angular/cli new @a } elseif (Test-CachedCommand ng) { ng new @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:ng-new -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx @angular/cli new @a } elseif (Get-Command ng -ErrorAction SilentlyContinue) { ng new @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
  }
}

# Angular serve - start development server
if (-not (Test-Path Function:ng-serve -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:ng-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx @angular/cli serve @a } elseif (Test-CachedCommand ng) { ng serve @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:ng-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx @angular/cli serve @a } elseif (Get-Command ng -ErrorAction SilentlyContinue) { ng serve @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
  }
}


