# ===============================================
# 28-jq-yq.ps1
# jq and yq helpers (guarded)
# ===============================================

<#
Register jq/yq helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# jq to JSON converter - convert JSON to compact JSON
if (-not (Test-Path Function:jq2json -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:jq2json -Value { param($f) if (Test-HasCommand jq) { jq -c . $f } else { Write-Warning 'jq not found' } } -Force | Out-Null
}

# yq to JSON converter - convert YAML to JSON
if (-not (Test-Path Function:yq2json -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:yq2json -Value { param($f) if (Test-HasCommand yq) { yq eval -o=json $f } else { Write-Warning 'yq not found' } } -Force | Out-Null
}
