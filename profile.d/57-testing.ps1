# ===============================================
# 57-testing.ps1
# Testing frameworks helpers (guarded)
# ===============================================

<#
Register testing framework helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Jest - JavaScript testing framework
if (-not (Test-Path Function:jest -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:jest -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand jest) { jest @a } else { npx jest @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:jest -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command jest -ErrorAction SilentlyContinue) { jest @a } else { npx jest @a } } -Force | Out-Null
    }
}

# Vitest - next generation testing framework
if (-not (Test-Path Function:vitest -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:vitest -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand vitest) { vitest @a } else { npx vitest @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:vitest -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command vitest -ErrorAction SilentlyContinue) { vitest @a } else { npx vitest @a } } -Force | Out-Null
    }
}

# Playwright - end-to-end testing framework
if (-not (Test-Path Function:playwright -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:playwright -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand playwright) { playwright @a } else { npx playwright @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:playwright -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command playwright -ErrorAction SilentlyContinue) { playwright @a } else { npx playwright @a } } -Force | Out-Null
    }
}

# Cypress - JavaScript end-to-end testing framework
if (-not (Test-Path Function:cypress -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:cypress -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand cypress) { cypress @a } else { npx cypress @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:cypress -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command cypress -ErrorAction SilentlyContinue) { cypress @a } else { npx cypress @a } } -Force | Out-Null
    }
}

# Mocha - feature-rich JavaScript test framework
if (-not (Test-Path Function:mocha -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:mocha -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand mocha) { mocha @a } else { npx mocha @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:mocha -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command mocha -ErrorAction SilentlyContinue) { mocha @a } else { npx mocha @a } } -Force | Out-Null
    }
}




















