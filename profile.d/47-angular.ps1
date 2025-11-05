# ===============================================
# 47-angular.ps1
# Angular CLI helpers (guarded)
# ===============================================

<#
Register Angular helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Angular execute - run angular with arguments
if (-not (Test-Path Function:ng -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ng -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx @angular/cli @a } elseif (Test-HasCommand ng) { ng @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
}

# Angular new project - create new Angular application
if (-not (Test-Path Function:ng-new -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ng-new -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx @angular/cli new @a } elseif (Test-HasCommand ng) { ng new @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
}

# Angular serve - start development server
if (-not (Test-Path Function:ng-serve -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ng-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx @angular/cli serve @a } elseif (Test-HasCommand ng) { ng serve @a } else { Write-Warning 'npx or ng not found' } } -Force | Out-Null
}
