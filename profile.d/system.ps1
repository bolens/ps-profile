# ===============================================
# system.ps1
# System utilities (shell-like helpers adapted for PowerShell)
# ===============================================
# Provides Unix-style command aliases and helper functions for common system operations.
# These functions wrap PowerShell cmdlets to provide familiar command names for users
# coming from Unix/Linux environments or who prefer shorter command names.
# Tier: essential
# Dependencies: bootstrap, env

# ===============================================
# System Modules - DEFERRED LOADING
# ===============================================
# Modules are now loaded on-demand via Ensure-System function.
# See files-module-registry.ps1 for module mappings.
#
# OLD EAGER LOADING CODE (commented out for performance):
# Previously loaded 6 modules eagerly at startup, adding 200-500ms to load time.
# Now modules are loaded only when Ensure-System is called.

# Lazy bulk initializer for system utility functions
<#
.SYNOPSIS
    Sets up all system utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads system modules from the system subdirectory.
#>
function Ensure-System {
    if ($global:SystemInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-System' -BaseDir $PSScriptRoot
    }

    # Mark as initialized
    $global:SystemInitialized = $true
}
