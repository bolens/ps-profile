# ===============================================
# 57-testing.ps1
# Testing frameworks helpers (guarded)
# ===============================================

<#
Register testing framework helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Jest - JavaScript testing framework
if (-not (Test-Path Function:jest -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:jest -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand jest) { jest @a } else { npx jest @a } } -Force | Out-Null
}

# Vitest - next generation testing framework
if (-not (Test-Path Function:vitest -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:vitest -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand vitest) { vitest @a } else { npx vitest @a } } -Force | Out-Null
}

# Playwright - end-to-end testing framework
if (-not (Test-Path Function:playwright -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:playwright -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand playwright) { playwright @a } else { npx playwright @a } } -Force | Out-Null
}

# Cypress - JavaScript end-to-end testing framework
if (-not (Test-Path Function:cypress -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:cypress -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand cypress) { cypress @a } else { npx cypress @a } } -Force | Out-Null
}

# Mocha - feature-rich JavaScript test framework
if (-not (Test-Path Function:mocha -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:mocha -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand mocha) { mocha @a } else { npx mocha @a } } -Force | Out-Null
}
