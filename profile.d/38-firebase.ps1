# ===============================================
# 38-firebase.ps1
# Firebase CLI helpers (guarded)
# ===============================================

<#
Register Firebase helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Firebase alias - run firebase with arguments
if (-not (Test-Path Function:fb -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:fb -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand fb) { fb @a } else { Write-Warning 'fb not found' } } -Force | Out-Null
}

# Firebase deploy - deploy to Firebase hosting
if (-not (Test-Path Function:fb-deploy -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:fb-deploy -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand firebase) { firebase deploy @a } else { Write-Warning 'firebase not found' } } -Force | Out-Null
}

# Firebase serve - start local development server
if (-not (Test-Path Function:fb-serve -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:fb-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand firebase) { firebase serve @a } else { Write-Warning 'firebase not found' } } -Force | Out-Null
}
