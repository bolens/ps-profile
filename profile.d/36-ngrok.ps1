# ===============================================
# 36-ngrok.ps1
# Ngrok tunneling helpers (guarded)
# ===============================================

<#
Register Ngrok helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Ngrok execute - run ngrok with arguments
if (-not (Test-Path Function:ngrok -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ngrok -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand ngrok) { ngrok @a } else { Write-Warning 'ngrok not found' } } -Force | Out-Null
}

# Ngrok HTTP tunnel - expose local HTTP server
if (-not (Test-Path Function:ngrok-http -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ngrok-http -Value { param($port = 80) if (Test-HasCommand ngrok) { ngrok http $port } else { Write-Warning 'ngrok not found' } } -Force | Out-Null
}

# Ngrok TCP tunnel - expose local TCP service
if (-not (Test-Path Function:ngrok-tcp -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ngrok-tcp -Value { param($port) if (Test-HasCommand ngrok) { ngrok tcp $port } else { Write-Warning 'ngrok not found' } } -Force | Out-Null
}
