# ===============================================
# 16-terraform.ps1
# Terraform helpers (guarded)
# ===============================================

<#
Register terraform helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Terraform alias - run terraform with arguments
if (-not (Test-Path Function:tf -ErrorAction SilentlyContinue)) { Set-Item -Path Function:tf -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command tf -ErrorAction SilentlyContinue) { tf @a } else { Write-Warning 'tf not found' } } -Force | Out-Null }

# Terraform init - initialize working directory
if (-not (Test-Path Function:tfi -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:tfi -Value { if (Test-CachedCommand terraform) { terraform init @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:tfi -Value { if (Get-Command terraform -ErrorAction SilentlyContinue) { terraform init @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  }
}

# Terraform plan - show execution plan
if (-not (Test-Path Function:tfp -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:tfp -Value { if (Test-CachedCommand terraform) { terraform plan @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:tfp -Value { if (Get-Command terraform -ErrorAction SilentlyContinue) { terraform plan @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  }
}

# Terraform apply - apply changes
if (-not (Test-Path Function:tfa -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:tfa -Value { if (Test-CachedCommand terraform) { terraform apply @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:tfa -Value { if (Get-Command terraform -ErrorAction SilentlyContinue) { terraform apply @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  }
}

# Terraform destroy - destroy infrastructure
if (-not (Test-Path Function:tfd -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:tfd -Value { if (Test-CachedCommand terraform) { terraform destroy @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:tfd -Value { if (Get-Command terraform -ErrorAction SilentlyContinue) { terraform destroy @args } else { Write-Warning 'terraform not found' } } -Force | Out-Null
  }
}


