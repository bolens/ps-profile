# ===============================================
# 43-laravel.ps1
# Laravel framework helpers (guarded)
# ===============================================

<#
Register Laravel helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Laravel artisan command - run artisan commands
if (-not (Test-Path Function:artisan -ErrorAction SilentlyContinue)) { Set-Item -Path Function:artisan -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command artisan -ErrorAction SilentlyContinue) { php artisan @a } else { Write-Warning 'artisan not found' } } -Force | Out-Null }

# Laravel artisan alias - run artisan commands
if (-not (Test-Path Function:art -ErrorAction SilentlyContinue)) { Set-Item -Path Function:art -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command art -ErrorAction SilentlyContinue) { php artisan @a } else { Write-Warning 'art not found' } } -Force | Out-Null }

# Laravel new project - create new Laravel application
if (-not (Test-Path Function:laravel-new -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:laravel-new -Value { param($name) if (Test-CachedCommand composer) { composer create-project laravel/laravel $name } else { Write-Warning 'composer not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:laravel-new -Value { param($name) if (Get-Command composer -ErrorAction SilentlyContinue) { composer create-project laravel/laravel $name } else { Write-Warning 'composer not found' } } -Force | Out-Null
    }
}

























