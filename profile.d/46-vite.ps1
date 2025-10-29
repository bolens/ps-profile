# ===============================================
# 46-vite.ps1
# Vite build tool helpers (guarded)
# ===============================================

<#
Register Vite helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Vite execute - run vite with arguments
if (-not (Test-Path Function:vite -ErrorAction SilentlyContinue)) { Set-Item -Path Function:vite -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command vite -ErrorAction SilentlyContinue) { npx vite @a } else { Write-Warning 'vite not found' } } -Force | Out-Null }

# Create Vite project - scaffold new Vite project
if (-not (Test-Path Function:create-vite -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:create-vite -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx create-vite @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:create-vite -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx create-vite @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}

# Vite dev server - start development server
if (-not (Test-Path Function:vite-dev -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:vite-dev -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx vite dev @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:vite-dev -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx vite dev @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}

# Vite build - create production build
if (-not (Test-Path Function:vite-build -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:vite-build -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx vite build @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:vite-build -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx vite build @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}










