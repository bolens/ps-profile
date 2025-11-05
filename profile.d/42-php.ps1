# ===============================================
# 42-php.ps1
# PHP development helpers (guarded)
# ===============================================

<#
Register PHP helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# PHP execute - run php with arguments
if (-not (Test-Path Function:php -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:php -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand php) { php @a } else { Write-Warning 'php not found' } } -Force | Out-Null
}

# PHP built-in server - start development server
if (-not (Test-Path Function:php-server -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:php-server -Value { param($port = 8000) if (Test-HasCommand php) { php -s localhost:$port } else { Write-Warning 'php not found' } } -Force | Out-Null
}

# Composer - PHP dependency manager
if (-not (Test-Path Function:composer -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:composer -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand composer) { composer @a } else { Write-Warning 'composer not found' } } -Force | Out-Null
}
