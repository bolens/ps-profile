<#
# 01-env.ps1

Set environment variable defaults in a safe, idempotent way. Do not
overwrite existing values; only set sensible defaults when unset.
#>

try {
    if ($null -ne (Get-Variable -Name 'EnvDefaultsLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Only set defaults if not already configured by the user or the system.
    if (-not $env:EDITOR) { $env:EDITOR = 'code' }
    if (-not $env:GIT_EDITOR) { $env:GIT_EDITOR = 'code --wait' }
    if (-not $env:VISUAL) { $env:VISUAL = 'code' }

    # Example: append user-local bin to PATH if present (non-destructive)
    # Use cross-platform home directory helper
    $userHome = if (Test-Path Function:\Get-UserHome) {
        Get-UserHome
    }
    elseif ($env:HOME) {
        $env:HOME
    }
    else {
        $env:USERPROFILE
    }
    
    if ($userHome) {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $userBin = Join-Path $userHome '.local' 'bin'
        if ((Test-Path $userBin) -and ($env:Path -notlike "*$([regex]::Escape($userBin))*")) {
            $env:Path = "$userBin$pathSeparator$env:Path"
        }
    }

    Set-Variable -Name 'EnvDefaultsLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Env fragment failed: $($_.Exception.Message)" }
}
