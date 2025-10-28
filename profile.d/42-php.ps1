# ===============================================
# 42-php.ps1
# PHP development helpers (guarded)
# ===============================================

<#
Register PHP helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# PHP execute - run php with arguments
if (-not (Test-Path Function:php -ErrorAction SilentlyContinue)) { Set-Item -Path Function:php -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command php -ErrorAction SilentlyContinue) { php @a } else { Write-Warning 'php not found' } } -Force | Out-Null }

# PHP built-in server - start development server
if (-not (Test-Path Function:php-server -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:php-server -Value { param($port = 8000) if (Test-CachedCommand php) { php -s localhost:$port } else { Write-Warning 'php not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:php-server -Value { param($port = 8000) if (Get-Command php -ErrorAction SilentlyContinue) { php -s localhost:$port } else { Write-Warning 'php not found' } } -Force | Out-Null
  }
}

# Composer - PHP dependency manager
if (-not (Test-Path Function:composer -ErrorAction SilentlyContinue)) { Set-Item -Path Function:composer -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command composer -ErrorAction SilentlyContinue) { composer @a } else { Write-Warning 'composer not found' } } -Force | Out-Null }







