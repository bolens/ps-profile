<#

<#

# Tier: essential
# Dependencies: bootstrap, env
<#

<#
# scoop-completion.ps1

Idempotent lazy-loading setup for Scoop tab completion.

This fragment discovers the Scoop completion module path but does not import it immediately.
Instead, it creates an Enable-ScoopCompletion function that can be called on-demand to enable
completion features. This lazy loading approach keeps profile startup fast.
#>

try {
    # Idempotency check: skip if already processed
    if ($null -ne (Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Discover Scoop completion module path using ScoopDetection module if available
    $scoopCompletion = $null
    if (Get-Command Get-ScoopCompletionPath -ErrorAction SilentlyContinue) {
        $scoopCompletion = Get-ScoopCompletionPath
    }
    else {
        # Fallback: manually detect Scoop installation and construct completion path
        # Check both global and local Scoop installations
        $scoopRoot = $null
        
        # Check global Scoop installation first
        if ($env:SCOOP_GLOBAL) {
            $candidate = $env:SCOOP_GLOBAL
            if ($candidate -and -not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue)) {
                $scoopRoot = $candidate
            }
        }
        
        # Check local Scoop installation
        if (-not $scoopRoot -and $env:SCOOP) {
            $candidate = $env:SCOOP
            if ($candidate -and -not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue)) {
                $scoopRoot = $candidate
            }
        }
        
        # Check default user location (cross-platform compatible)
        if (-not $scoopRoot -and ($env:USERPROFILE -or $env:HOME)) {
            $userHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
            $defaultScoop = Join-Path $userHome 'scoop'
            if ($defaultScoop -and -not [string]::IsNullOrWhiteSpace($defaultScoop) -and (Test-Path -LiteralPath $defaultScoop -PathType Container -ErrorAction SilentlyContinue)) {
                $scoopRoot = $defaultScoop
            }
        }
        
        if ($scoopRoot) {
            # Construct path to Scoop completion module (standard Scoop installation structure)
            $candidate = Join-Path $scoopRoot 'apps' 'scoop' 'current' 'supporting' 'completion' 'Scoop-Completion.psd1'
            if ($candidate -and -not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue)) {
                $scoopCompletion = $candidate
            }
        }
    }

    if ($scoopCompletion) {
        # Create lazy-loading function: Enable-ScoopCompletion imports the module on first call
        # This defers the import until the user actually needs tab completion, improving startup time
        if (-not (Test-Path Function:\Enable-ScoopCompletion)) {
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
