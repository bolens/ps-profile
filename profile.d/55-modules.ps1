<#
# 55-modules.ps1

Best-effort imports for commonly used modules (keeps main profile tidy).
Do not throw on failure; only import when available.
#>

try {
    # This fragment used to eagerly try Import-Module for a few
    # convenience modules which caused module discovery/autoload at
    # profile dot-source time. To keep startup fast we create tiny
    # Function: provider wrappers that import the module on first use.

    if ($null -ne (Get-Variable -Name 'ModulesLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Expose explicit enable helpers so scripts can opt-in to loading.
    if (-not (Test-Path 'Function:Enable-PoshGit')) {
        New-Item -Path 'Function:Enable-PoshGit' -Value {
            param()
            Import-Module -Name 'posh-git' -ErrorAction SilentlyContinue
            return $LASTEXITCODE -eq 0 -or $true
        } -Force | Out-Null
    }

    # PSReadLine enable helper (idempotent if other fragments already declare it)
    if (-not (Test-Path 'Function:Enable-PSReadLine')) {
        New-Item -Path 'Function:Enable-PSReadLine' -Value {
            param()
            Import-Module -Name 'PSReadLine' -ErrorAction SilentlyContinue
            return $LASTEXITCODE -eq 0 -or $true
        } -Force | Out-Null
    }

    Set-Variable -Name 'ModulesLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Modules fragment failed: $($_.Exception.Message)" }
}























