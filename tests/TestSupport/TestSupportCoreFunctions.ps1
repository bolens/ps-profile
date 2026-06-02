# ===============================================
# TestSupportCoreFunctions.ps1
# Canonical TestSupport helpers restored between test files
# ===============================================

function Mark-TestCommandsUnavailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$CommandNames
    )

    if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
    }

    if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    foreach ($command in $CommandNames) {
        Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\global:$command" -Force -ErrorAction SilentlyContinue

        $removed = $null
        $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}
