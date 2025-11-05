# ===============================================
# 21-kube.ps1
# kubectl / minikube helpers
# ===============================================

<#
19-kube.ps1
Lightweight helpers for kubectl/minikube.

Notes:
- kubectl shorthands are authoritative in `profile.d/21-kubectl.ps1`.
- Keep this file cheap at dot-source: do not call Get-Command here. Instead
  register tiny forwarding stubs that perform a runtime check on first use.
#>

# minikube start/stop conveniences: register cheap stubs that only probe
# for `minikube` when invoked. Use Test-HasCommand which handles caching internally.
if (-not (Test-Path Function:\minikube-start)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:\minikube-start -Value { param($a) if (Test-HasCommand minikube) { minikube start @a } else { Write-Warning 'minikube not found' } } -Force | Out-Null
}

if (-not (Test-Path Function:\minikube-stop)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:\minikube-stop -Value { param($a) if (Test-HasCommand minikube) { minikube stop @a } else { Write-Warning 'minikube not found' } } -Force | Out-Null
}

# Do NOT duplicate kctx here; `15-kubectl.ps1` is authoritative for kubectl shorthands.
