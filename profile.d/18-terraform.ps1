# ===============================================
# 18-terraform.ps1
# Terraform helpers (guarded)
# ===============================================

<#
Register terraform helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Terraform alias - run terraform with arguments
if (-not (Test-Path Function:tf -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:tf -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand tf) { tf @a } else { Write-Warning 'tf not found' } } -Force | Out-Null
}

# Terraform init - initialize working directory
if (-not (Test-Path Function:tfi -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:tfi -Value { if (Test-HasCommand terraform) { terraform init @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
}

# Terraform plan - show execution plan
if (-not (Test-Path Function:tfp -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:tfp -Value { if (Test-HasCommand terraform) { terraform plan @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
}

# Terraform apply - apply changes
if (-not (Test-Path Function:tfa -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:tfa -Value { if (Test-HasCommand terraform) { terraform apply @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
}

# Terraform destroy - destroy infrastructure
if (-not (Test-Path Function:tfd -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:tfd -Value { if (Test-HasCommand terraform) { terraform destroy @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
}
