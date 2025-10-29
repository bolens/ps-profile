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
# for `minikube` when invoked. If `Test-CachedCommand` is available, prefer it.
if (-not (Test-Path Function:\minikube-start)) {
    # Register a stub that prefers Test-CachedCommand at runtime when available
    $sbStart = {
        param($a)
        if (Test-Path "Function:\Test-CachedCommand" -or Test-Path "Function:\global:Test-CachedCommand") {
            try { if (Test-CachedCommand minikube) { minikube start @a } else { Write-Warning 'minikube not found' } } catch { Write-Warning 'minikube check failed' }
        }
        else {
            if (Get-Command minikube -ErrorAction SilentlyContinue) { minikube start @a } else { Write-Warning 'minikube not found' }
        }
    }
    Set-Item -Path Function:\minikube-start -Value $sbStart -Force | Out-Null
}

if (-not (Test-Path Function:\minikube-stop)) {
    $sbStop = {
        param($a)
        if (Test-Path "Function:\Test-CachedCommand" -or Test-Path "Function:\global:Test-CachedCommand") {
            try { if (Test-CachedCommand minikube) { minikube stop @a } else { Write-Warning 'minikube not found' } } catch { Write-Warning 'minikube check failed' }
        }
        else {
            if (Get-Command minikube -ErrorAction SilentlyContinue) { minikube stop @a } else { Write-Warning 'minikube not found' }
        }
    }
    Set-Item -Path Function:\minikube-stop -Value $sbStop -Force | Out-Null
}

# Do NOT duplicate kctx here; `15-kubectl.ps1` is authoritative for kubectl shorthands.
















