# ===============================================
# 45-nextjs.ps1
# Next.js development helpers (guarded)
# ===============================================

<#
Register Next.js helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Next.js dev server - start development server
if (-not (Test-Path Function:next-dev -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:next-dev -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx next dev @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:next-dev -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx next dev @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}

# Next.js build - create production build
if (-not (Test-Path Function:next-build -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:next-build -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx next build @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:next-build -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx next build @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}

# Next.js start - start production server
if (-not (Test-Path Function:next-start -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:next-start -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx next start @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:next-start -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx next start @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}

# Create Next.js app - bootstrap a new Next.js application
if (-not (Test-Path Function:create-next-app -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:create-next-app -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx create-next-app @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:create-next-app -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx create-next-app @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
    }
}














