# ===============================================
# 37-deno.ps1
# Deno JavaScript runtime helpers (guarded)
# ===============================================

<#
Register Deno helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Deno execute - run deno with arguments
if (-not (Test-Path Function:deno -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:deno -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand deno) { deno @a } else { Write-Warning 'deno not found' } } -Force | Out-Null
}

# Deno run - execute Deno scripts
if (-not (Test-Path Function:deno-run -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:deno-run -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand deno) { deno run @a } else { Write-Warning 'deno not found' } } -Force | Out-Null
}

# Deno task - run defined tasks from deno.json
if (-not (Test-Path Function:deno-task -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:deno-task -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand deno) { deno task @a } else { Write-Warning 'deno not found' } } -Force | Out-Null
}
