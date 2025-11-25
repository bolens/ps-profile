<#
# 01-env.ps1

Set environment variable defaults in a safe, idempotent way. Do not
overwrite existing values; only set sensible defaults when unset.
#>

try {
    # Idempotency check: skip if already loaded (prevents duplicate environment variable settings)
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName '01-env') { return }
    }

    # Set editor defaults only if not already configured (respects user/system preferences)
    if (-not $env:EDITOR) { $env:EDITOR = 'code' }
    if (-not $env:GIT_EDITOR) { $env:GIT_EDITOR = 'code --wait' }
    if (-not $env:VISUAL) { $env:VISUAL = 'code' }

    # Add user-local bin directory to PATH if it exists (cross-platform home directory resolution)
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
        # Only add if directory exists and isn't already in PATH (non-destructive)
        if ((Test-Path $userBin) -and ($env:Path -notlike "*$([regex]::Escape($userBin))*")) {
            $env:Path = "$userBin$pathSeparator$env:Path"
        }
    }

    # Mark fragment as loaded for idempotency tracking
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName '01-env'
    }
    else {
        Set-Variable -Name 'EnvDefaultsLoaded' -Value $true -Scope Global -Force
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Env fragment failed: $($_.Exception.Message)" }
}
