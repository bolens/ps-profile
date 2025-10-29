<#
# 60-local-overrides.ps1

This file is intended for machine-specific tweaks and should be in the
user's private configuration. By default it is not created; add it to
.gitignore if you plan to keep secrets or local-only settings here.

The fragment is loaded last so it can intentionally override earlier
definitions.
#>

try {
    # only load if present; do not error if absent
    $local = Join-Path (Split-Path $PROFILE) 'profile.d\local-overrides.ps1'
    if (Test-Path $local) { .$local }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Local overrides failed: $($_.Exception.Message)" }
}
















