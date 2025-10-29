# ===============================================
# 58-build-tools.ps1
# Build tools and dev servers helpers (guarded)
# ===============================================

<#
Register build tools and development server helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# turbo - monorepo build system and task runner
if (-not (Test-Path Function:turbo -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:turbo -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand turbo) { turbo @a } else { npx turbo @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:turbo -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command turbo -ErrorAction SilentlyContinue) { turbo @a } else { npx turbo @a } } -Force | Out-Null
    }
}

# esbuild - extremely fast JavaScript bundler
if (-not (Test-Path Function:esbuild -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:esbuild -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand esbuild) { esbuild @a } else { npx esbuild @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:esbuild -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command esbuild -ErrorAction SilentlyContinue) { esbuild @a } else { npx esbuild @a } } -Force | Out-Null
    }
}

# rollup - JavaScript module bundler
if (-not (Test-Path Function:rollup -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:rollup -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand rollup) { rollup @a } else { npx rollup @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:rollup -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command rollup -ErrorAction SilentlyContinue) { rollup @a } else { npx rollup @a } } -Force | Out-Null
    }
}

# serve - static file serving and directory listing
if (-not (Test-Path Function:serve -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand serve) { serve @a } else { npx serve @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command serve -ErrorAction SilentlyContinue) { serve @a } else { npx serve @a } } -Force | Out-Null
    }
}

# http-server - simple zero-configuration command-line http server
if (-not (Test-Path Function:http-server -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:http-server -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand http-server) { http-server @a } else { npx http-server @a } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:http-server -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command http-server -ErrorAction SilentlyContinue) { http-server @a } else { npx http-server @a } } -Force | Out-Null
    }
}












