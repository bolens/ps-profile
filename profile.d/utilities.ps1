# ===============================================
# utilities.ps1
# General-purpose utility functions for system, network, history, and filesystem operations
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

# ===============================================
# Utility Modules - DEFERRED LOADING
# ===============================================
# Modules are now loaded on-demand via Ensure-Utilities function.
# See files-module-registry.ps1 for module mappings.
#
# OLD EAGER LOADING CODE (commented out for performance):
# Previously loaded 7 modules eagerly at startup, adding 500ms-1s to load time.
# Now modules are loaded only when Ensure-Utilities is called.

# Lazy bulk initializer for utility functions
<#
.SYNOPSIS
    Sets up all utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads utility modules from the utilities-modules subdirectory.
#>
function Ensure-Utilities {
    if ($global:UtilitiesInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-Utilities' -BaseDir $PSScriptRoot
    }

    # Mark as initialized
    $global:UtilitiesInitialized = $true
}
