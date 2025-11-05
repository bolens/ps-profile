# ===============================================
# 58-build-tools.ps1
# Build tools and dev servers helpers (guarded)
# ===============================================

<#
Register build tools and development server helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# turbo - monorepo build system and task runner
if (-not (Test-Path Function:turbo -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:turbo -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand turbo) { turbo @a } else { npx turbo @a } } -Force | Out-Null
}

# esbuild - extremely fast JavaScript bundler
if (-not (Test-Path Function:esbuild -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:esbuild -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand esbuild) { esbuild @a } else { npx esbuild @a } } -Force | Out-Null
}

# rollup - JavaScript module bundler
if (-not (Test-Path Function:rollup -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rollup -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand rollup) { rollup @a } else { npx rollup @a } } -Force | Out-Null
}

# serve - static file serving and directory listing
if (-not (Test-Path Function:serve -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand serve) { serve @a } else { npx serve @a } } -Force | Out-Null
}

# http-server - simple zero-configuration command-line http server
if (-not (Test-Path Function:http-server -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:http-server -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand http-server) { http-server @a } else { npx http-server @a } } -Force | Out-Null
}
