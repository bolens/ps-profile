<#
profile.d/20-starship.ps1

Idempotent, quiet initialization of the Starship prompt for PowerShell.

Behavior:
 - If the `starship` command is available, this fragment will call
   `starship init powershell` and execute the generated initialization
   code.
 - The fragment is idempotent: it will only initialize once per session.
 - It is quiet when dot-sourced (returns no output) so the interactive
   shell startup remains clean.

Notes:
 - Prefer creating a global flag `$Global:StarshipInitialized` instead of
   relying on prompt function inspection; this keeps the check cheap.
 - If `PS_PROFILE_DEBUG` is set in your environment, this fragment will
   emit a verbose message to help debugging.
#>

try {
  # Define a lazy initializer for starship so startup remains snappy. Consumers
  # (like the prompt proxy) can call Initialize-Starship to set up starship
  # at the first prompt draw instead of at profile load.
  if (-not (Test-Path Function:Initialize-Starship -ErrorAction SilentlyContinue)) {
    function Initialize-Starship {
      try {
        if ($null -ne (Get-Variable -Name 'StarshipInitialized' -Scope Global -ErrorAction SilentlyContinue)) { return }
        $starCmd = Get-Command starship -ErrorAction SilentlyContinue
        if (-not $starCmd) { return }
        $initScript = & $starCmd.Source init powershell 2>$null
        if ($initScript) {
          # Write the initialization script to a temp file and dot-source it to avoid Invoke-Expression.
          $temp = [System.IO.Path]::GetTempFileName() + '.ps1'
          try {
            $null = $initScript | Out-File -FilePath $temp -Encoding UTF8
            if (Test-Path $temp) {.$temp }
          } finally {
            if (Test-Path $temp) { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
          }
          Set-Variable -Name 'StarshipInitialized' -Value $true -Scope Global -Force
          if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Starship initialized via $($starCmd.Source)" }
        }
      } catch {
        if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-Starship failed: $($_.Exception.Message)" }
      }
    }
  }
} catch {
  if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Starship fragment failed to define initializer: $($_.Exception.Message)" }
}
