<#

<#

# Tier: standard
# Dependencies: bootstrap, env
<#

<#
# local-overrides.ps1

This file is intended for machine-specific tweaks and should be in the
user's private configuration. By default it is not created; add it to
.gitignore if you plan to keep secrets or local-only settings here.

The fragment is loaded last so it can intentionally override earlier
definitions.
#>

# Local overrides loading is disabled by default due to performance issues
# (dot-sourcing non-existent files can take 100+ seconds on some filesystems)
# To enable, set $env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES = '1'
if ($env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES -eq '1') {
    try {
        # only load if present; do not error if absent
        # Use $ProfileFragmentRoot (set by profile loader) or $PSScriptRoot as fallback
        $profileDir = $null
        if ($global:ProfileFragmentRoot -and -not [string]::IsNullOrWhiteSpace($global:ProfileFragmentRoot)) {
            $profileDir = $global:ProfileFragmentRoot
        }
        elseif ($PSScriptRoot -and -not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            $profileDir = $PSScriptRoot
        }
        
        if ($profileDir) {
            $local = Join-Path $profileDir 'local-overrides.ps1'
            if ($local -and -not [string]::IsNullOrWhiteSpace($local)) {
                # Skip Test-Path check (can be 40+ seconds) and just try to load
                # If file doesn't exist, dot-sourcing will fail silently
                try {
                    . $local
                }
                catch {
                    # File doesn't exist or failed to load - silently ignore
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Verbose "Local overrides file not found or failed to load: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Local overrides failed: $($_.Exception.Message)" }
    }
}
