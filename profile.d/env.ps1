<#

<#

# Tier: essential
# Dependencies: bootstrap
<#
# env.ps1

Set environment variable defaults in a safe, idempotent way. Do not
overwrite existing values; only set sensible defaults when unset.
#>

try {
    # Idempotency check: skip if already loaded (prevents duplicate environment variable settings)
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'env') { return }
    }

    # Load .env files from repository root (project-specific environment variables)
    # This allows users to set preferences like PS_PYTHON_PACKAGE_MANAGER, PS_NODE_PACKAGE_MANAGER, etc.
    # Try to detect repository root from profile location
    $repoRoot = $null
    $profileDir = Split-Path -Parent $PSScriptRoot
    $gitPath = if ($profileDir -and -not [string]::IsNullOrWhiteSpace($profileDir)) { Join-Path $profileDir '.git' } else { $null }
    if ($gitPath -and (Test-Path -LiteralPath $gitPath)) {
        $repoRoot = $profileDir
    }
    else {
        $parentDir = Split-Path -Parent $profileDir
        $parentGitPath = if ($parentDir -and -not [string]::IsNullOrWhiteSpace($parentDir)) { Join-Path $parentDir '.git' } else { $null }
        if ($parentGitPath -and (Test-Path -LiteralPath $parentGitPath)) {
            $repoRoot = $parentDir
        }
    }
    
    if ($repoRoot) {
        $envFileModule = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'EnvFile.psm1'
        if ($envFileModule -and -not [string]::IsNullOrWhiteSpace($envFileModule) -and (Test-Path -LiteralPath $envFileModule)) {
            try {
                Import-Module $envFileModule -DisableNameChecking -ErrorAction Stop
                Initialize-EnvFiles -RepoRoot $repoRoot -ErrorAction SilentlyContinue
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to load .env files: $($_.Exception.Message)"
                }
            }
        }
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
        if (($userBin -and
                -not [string]::IsNullOrWhiteSpace($userBin) -and
                (Test-Path -LiteralPath $userBin)) -and
            ($env:Path -notlike "*$([regex]::Escape($userBin))*")) {
            $env:Path = "$userBin$pathSeparator$env:Path"
        }
    }

    # Mark fragment as loaded for idempotency tracking
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'env'
    }
    else {
        Set-Variable -Name 'EnvDefaultsLoaded' -Value $true -Scope Global -Force
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Env fragment failed: $($_.Exception.Message)" }
}
