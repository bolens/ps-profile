# ===============================================
# 43-laravel.ps1
# Laravel framework helpers (guarded)
# ===============================================

<#
Register Laravel helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Laravel artisan command - run artisan commands
if (-not (Test-Path Function:artisan -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:artisan -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand artisan) { php artisan @a } else { Write-Warning 'artisan not found' } } -Force | Out-Null
}

# Laravel artisan alias - run artisan commands
if (-not (Test-Path Function:art -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:art -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand art) { php artisan @a } else { Write-Warning 'art not found' } } -Force | Out-Null
}

# Laravel new project - create new Laravel application
if (-not (Test-Path Function:laravel-new -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:laravel-new -Value { param($name) if (Test-HasCommand composer) { composer create-project laravel/laravel $name } else { Write-Warning 'composer not found' } } -Force | Out-Null
}
