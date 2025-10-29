# ===============================================
# 17-kubectl.ps1
# Small kubectl shorthands and helpers
# ===============================================

# Lazy kubectl helpers: use Test-CachedCommand (from 03-files.ps1) if available
# Define lightweight stubs that check for kubectl on first use to avoid
# calling Get-Command repeatedly at profile dot-source time.

# kubectl alias - run kubectl with arguments
if (-not (Test-Path Function:k -ErrorAction SilentlyContinue)) { Set-Item -Path Function:k -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command k -ErrorAction SilentlyContinue) { k @a } else { Write-Warning 'k not found' } } -Force | Out-Null }

# kubectl context switcher - switch Kubernetes context
if (-not (Test-Path Function:kn -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:kn -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command kubectl -ErrorAction SilentlyContinue) { kubectl config use-context @a } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}

# kubectl get - get Kubernetes resources
if (-not (Test-Path Function:kg -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:kg -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command kubectl -ErrorAction SilentlyContinue) { kubectl get @a } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}

# kubectl describe - describe Kubernetes resources
if (-not (Test-Path Function:kd -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:kd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command kubectl -ErrorAction SilentlyContinue) { kubectl Describe @a } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}

# kubectl context - show current context
if (-not (Test-Path Function:kctx -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:kctx -Value { if (Get-Command kubectl -ErrorAction SilentlyContinue) { kubectl config current-context } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}








