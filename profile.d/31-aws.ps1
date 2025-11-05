# ===============================================
# 31-aws.ps1
# AWS CLI helpers (guarded)
# ===============================================

<#
Register AWS CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# AWS execute - run aws with arguments
if (-not (Test-Path Function:aws -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:aws -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand aws) { aws @a } else { Write-Warning 'aws not found' } } -Force | Out-Null
}

# AWS profile switcher - set AWS profile
if (-not (Test-Path Function:aws-profile -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:aws-profile -Value { param($p) if (Test-HasCommand aws) { $env:AWS_PROFILE = $p; Write-Host "AWS profile set to: $p" } else { Write-Warning 'aws not found' } } -Force | Out-Null
}

# AWS region switcher - set AWS region
if (-not (Test-Path Function:aws-region -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:aws-region -Value { param($r) if (Test-HasCommand aws) { $env:AWS_REGION = $r; Write-Host "AWS region set to: $r" } else { Write-Warning 'aws not found' } } -Force | Out-Null
}
