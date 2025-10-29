# ===============================================
# 32-bun.ps1
# Bun JavaScript runtime helpers (guarded)
# ===============================================

<#
Register Bun helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Bun execute - run bunx with arguments
if (-not (Test-Path Function:bunx -ErrorAction SilentlyContinue)) {
    # Bun execute - run bunx with arguments
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:bunx -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand bun) { bunx @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:bunx -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command bun -ErrorAction SilentlyContinue) { bunx @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
    }
}

# Bun run script - execute npm scripts with bun
if (-not (Test-Path Function:bun-run -ErrorAction SilentlyContinue)) {
    # Bun run script - execute npm scripts with bun
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:bun-run -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand bun) { bun run @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:bun-run -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command bun -ErrorAction SilentlyContinue) { bun run @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
    }
}

# Bun add package - install npm packages with bun
if (-not (Test-Path Function:bun-add -ErrorAction SilentlyContinue)) {
    # Bun add package - install npm packages with bun
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:bun-add -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand bun) { bun add @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:bun-add -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command bun -ErrorAction SilentlyContinue) { bun add @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
    }
}




















