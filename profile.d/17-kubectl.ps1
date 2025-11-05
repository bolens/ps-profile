# ===============================================
# 17-kubectl.ps1
# Small kubectl shorthands and helpers
# ===============================================

# Lazy kubectl helpers: use Test-HasCommand for efficient command checks
# Define lightweight stubs that check for kubectl on first use to avoid
# calling Get-Command repeatedly at profile dot-source time.

# kubectl alias - run kubectl with arguments
if (-not (Test-Path Function:k -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:k -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand k) { k @a } else { Write-Warning 'k not found' } } -Force | Out-Null
}

# kubectl context switcher - switch Kubernetes context
if (-not (Test-Path Function:kn -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:kn -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand kubectl) { kubectl config use-context @a } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}

# kubectl get - get Kubernetes resources
if (-not (Test-Path Function:kg -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:kg -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand kubectl) { kubectl get @a } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}

# kubectl describe - describe Kubernetes resources
if (-not (Test-Path Function:kd -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:kd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand kubectl) { kubectl Describe @a } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}

# kubectl context - show current context
if (-not (Test-Path Function:kctx -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:kctx -Value { if (Test-HasCommand kubectl) { kubectl config current-context } else { Write-Warning 'kubectl not found' } } -Force | Out-Null
}
