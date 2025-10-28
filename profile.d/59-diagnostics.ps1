<#
# 59-diagnostics.ps1

Small diagnostics helpers that are only verbose when `PS_PROFILE_DEBUG` is
set. Useful to surface environment and tool status without polluting normal
interactive startup.
#>

# Register diagnostics helpers
try {
  if ($null -ne (Get-Variable -Name 'DiagnosticsLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

  if ($env:PS_PROFILE_DEBUG) {
    # Show profile diagnostics - PowerShell version, PATH, Podman status
    function Show-ProfileDiagnostic {
      Write-Host "-- Profile diagnostic --"
      Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
      Write-Host "PATH entries:"
      $env:Path -split ';' | ForEach-Object { Write-Host " - $_" }
      Write-Host "Podman machine(s):"; podman machine list | Out-Host
      Write-Host "Configured podman connections:"; podman system connection list | Out-Host
    }
  }

  Set-Variable -Name 'DiagnosticsLoaded' -Value $true -Scope Global -Force
} catch {
  if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Diagnostics fragment failed: $($_.Exception.Message)" }
}







