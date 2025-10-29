# ===============================================
# 35-ollama.ps1
# Ollama AI model helpers (guarded)
# ===============================================

<#
Register Ollama helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Ollama alias - run ollama with arguments
if (-not (Test-Path Function:ol -ErrorAction SilentlyContinue)) { Set-Item -Path Function:ol -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command ol -ErrorAction SilentlyContinue) { ol @a } else { Write-Warning 'ol not found' } } -Force | Out-Null }

# Ollama list - list available models
if (-not (Test-Path Function:ol-list -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:ol-list -Value { if (Test-CachedCommand ollama) { ollama list } else { Write-Warning 'ollama not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:ol-list -Value { if (Get-Command ollama -ErrorAction SilentlyContinue) { ollama list } else { Write-Warning 'ollama not found' } } -Force | Out-Null
    }
}

# Ollama run - run an AI model interactively
if (-not (Test-Path Function:ol-run -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:ol-run -Value { param($model) if (Test-CachedCommand ollama) { ollama run $model } else { Write-Warning 'ollama not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:ol-run -Value { param($model) if (Get-Command ollama -ErrorAction SilentlyContinue) { ollama run $model } else { Write-Warning 'ollama not found' } } -Force | Out-Null
    }
}

# Ollama pull - download an AI model
if (-not (Test-Path Function:ol-pull -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:ol-pull -Value { param($model) if (Test-CachedCommand ollama) { ollama pull $model } else { Write-Warning 'ollama not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:ol-pull -Value { param($model) if (Get-Command ollama -ErrorAction SilentlyContinue) { ollama pull $model } else { Write-Warning 'ollama not found' } } -Force | Out-Null
    }
}

























