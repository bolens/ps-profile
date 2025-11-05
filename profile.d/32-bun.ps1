# ===============================================
# 32-bun.ps1
# Bun JavaScript runtime helpers (guarded)
# ===============================================

<#
Register Bun helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Bun execute - run bunx with arguments
if (-not (Test-Path Function:bunx -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:bunx -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand bun) { bunx @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
}

# Bun run script - execute npm scripts with bun
if (-not (Test-Path Function:bun-run -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:bun-run -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand bun) { bun run @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
}

# Bun add package - install npm packages with bun
if (-not (Test-Path Function:bun-add -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:bun-add -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand bun) { bun add @a } else { Write-Warning 'bun not found' } } -Force | Out-Null
}
