<#
# 12-psreadline.ps1

Configures PSReadLine options (history, key bindings) in an idempotent
and feature-detecting manner so older PSReadLine versions remain compatible.
#>

try {
  if ($null -ne (Get-Variable -Name 'PSReadLineConfigured' -Scope Global -ErrorAction SilentlyContinue)) { return }

  # Only configure PSReadLine in interactive hosts (avoid work in non-interactive sessions)
  $isInteractive = $false
  try { $isInteractive = -not ([bool]$Host -and ($Host.Name -match 'Server|Console') -and ($null -eq $Host.UI.RawUI)) } catch { $isInteractive = $null -ne $Host }
  if (-not $isInteractive) { return }

  # Register a lazy enabler that imports and configures PSReadLine on demand.
  if (-not (Test-Path Function:\Enable-PSReadLine)) {
    $sb = {
      try {
        $historyDir = Join-Path $env:USERPROFILE '.local\share\powershell'
        if (-not (Test-Path $historyDir)) { New-Item -ItemType Directory -Path $historyDir -Force | Out-Null }
        $historyFile = Join-Path $historyDir 'PSReadLineHistory.txt'

        Import-Module PSReadLine -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Emacs
        Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
        Set-PSReadLineOption -MaximumHistoryCount 4096
        Set-PSReadLineOption -HistoryNoDuplicates:$true
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        $psrCmd = Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue
        if ($psrCmd -and $psrCmd.Parameters.ContainsKey('PredictionSource')) {
          Set-PSReadLineOption -PredictionSource Get-History
        }
        if ($psrCmd -and $psrCmd.Parameters.ContainsKey('PredictionViewStyle')) {
          Set-PSReadLineOption -PredictionViewStyle ListView
        }
        Set-PSReadLineOption -HistorySavePath $historyFile

        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit

        Set-Variable -Name 'PSReadLineConfigured' -Value $true -Scope Global -Force
      } catch {
        if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Enable-PSReadLine failed: $($_.Exception.Message)" }
      }
    }
    New-Item -Path Function:\Enable-PSReadLine -Value $sb -Force | Out-Null
  }

  # Optionally auto-enable in very interactive cases (only when explicitly requested via env)
  if ($env:PS_PROFILE_AUTOENABLE_PSREADLINE -eq '1') { Enable-PSReadLine }
} catch {
  if ($env:PS_PROFILE_DEBUG) { Write-Verbose "PSReadLine fragment failed: $($_.Exception.Message)" }
}







