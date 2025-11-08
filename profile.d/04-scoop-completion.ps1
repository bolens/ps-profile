<#
# 04-scoop-completion.ps1

Idempotent import of Scoop completion helpers when available.

This fragment implements the same behavior previously present in
`Microsoft.PowerShell_profile.ps1`: prefer using $env:SCOOP, fall back to
a legacy path if present, and import the Scoop-Completion module quietly.
#>

try {
    if ($null -ne (Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    $scoopCompletion = $null
    $scoopRoot = $null
    
    # Prefer the environment-provided path
    if ($env:SCOOP) {
        $scoopRoot = $env:SCOOP
    }
    # Check default user location (cross-platform compatible)
    elseif ($env:USERPROFILE -or $env:HOME) {
        $userHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
        $defaultScoop = Join-Path $userHome 'scoop'
        if (Test-Path $defaultScoop -PathType Container -ErrorAction SilentlyContinue) {
            $scoopRoot = $defaultScoop
        }
    }
    # Fallback to legacy path (for backward compatibility)
    if (-not $scoopRoot) {
        $legacyRoot = 'A:\'
        if (Test-Path $legacyRoot -PathType Container -ErrorAction SilentlyContinue) {
            $legacyScoop = Join-Path $legacyRoot 'scoop'
            if (Test-Path $legacyScoop -PathType Container -ErrorAction SilentlyContinue) {
                $scoopRoot = $legacyScoop
            }
        }
    }
    
    # Build completion module path if Scoop root found
    if ($scoopRoot) {
        $candidate = Join-Path $scoopRoot 'apps' 'scoop' 'current' 'supporting' 'completion' 'Scoop-Completion.psd1'
        if (Test-Path $candidate -PathType Leaf -ErrorAction SilentlyContinue) {
            $scoopCompletion = $candidate
        }
    }

    if ($scoopCompletion) {
        # Register a lazy enabler that imports the Scoop completion PSD1 when the user explicitly
        # requests completion features. This keeps dot-source cheap and avoids IO on startup.
        if (-not (Test-Path Function:\Enable-ScoopCompletion)) {
            # Create a minimal wrapper that imports the discovered PSD1 path when invoked.
            $p = $scoopCompletion
            $wrapper = {
                try {
                    Import-Module $using:p -ErrorAction SilentlyContinue
                    Set-Variable -Name 'ScoopCompletionLoaded' -Value $true -Scope Global -Force
                    Write-Output 'Scoop completion enabled (if available)'
                }
                catch {
                    Write-Warning 'Failed to enable Scoop completion'
                }
            }
            New-Item -Path Function:\Enable-ScoopCompletion -Value $wrapper -Force | Out-Null
        }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Scoop completion fragment failed: $($_.Exception.Message)" }
}
