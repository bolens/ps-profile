# ===============================================
# 35-ollama.ps1
# Ollama AI model helpers (guarded)
# ===============================================

<#
Register Ollama helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Ollama alias - run ollama with arguments
if (-not (Test-Path Function:ol -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ol -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand ol) { ol @a } else { Write-Warning 'ol not found' } } -Force | Out-Null
}

# Ollama list - list available models
if (-not (Test-Path Function:ol-list -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ol-list -Value { if (Test-HasCommand ollama) { ollama list } else { Write-Warning 'ollama not found' } } -Force | Out-Null
}

# Ollama run - run an AI model interactively
if (-not (Test-Path Function:ol-run -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ol-run -Value { param($model) if (Test-HasCommand ollama) { ollama run $model } else { Write-Warning 'ollama not found' } } -Force | Out-Null
}

# Ollama pull - download an AI model
if (-not (Test-Path Function:ol-pull -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ol-pull -Value { param($model) if (Test-HasCommand ollama) { ollama pull $model } else { Write-Warning 'ollama not found' } } -Force | Out-Null
}
