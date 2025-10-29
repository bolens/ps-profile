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
    # Prefer the environment-provided path without enumerating other locations
    if ($env:SCOOP) {
        $candidate = Join-Path $env:SCOOP 'apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
        if (Test-Path $candidate) { $scoopCompletion = $candidate }
    }
    # If not found via env, check the legacy path (cheap single Test-Path).
    # Avoid enumerating all drives; only test the legacy root quickly.
    if (-not $scoopCompletion) {
        $legacyRoot = 'A:\'
        if (Test-Path $legacyRoot -PathType Container -ErrorAction SilentlyContinue) {
            $legacy = 'A:\scoop\local\apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
            if (Test-Path $legacy -PathType Leaf -ErrorAction SilentlyContinue) { $scoopCompletion = $legacy }
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








