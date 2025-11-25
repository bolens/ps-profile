# ===============================================
# 05-utilities.ps1
# General-purpose utility functions for system, network, history, and filesystem operations
# ===============================================

# Load utility modules that provide system-level helper functions.
# These modules are loaded eagerly (not lazy) as they provide commonly-used utilities.
$utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
if (Test-Path $utilitiesModulesDir) {
    # System utilities (profile management, security, environment)
    $systemDir = Join-Path $utilitiesModulesDir 'system'
    . (Join-Path $systemDir 'utilities-profile.ps1')
    . (Join-Path $systemDir 'utilities-security.ps1')
    . (Join-Path $systemDir 'utilities-env.ps1')
    
    # Network utilities (connectivity, DNS, port checking)
    $networkDir = Join-Path $utilitiesModulesDir 'network'
    . (Join-Path $networkDir 'utilities-network.ps1')
    
    # Command history utilities (search, filtering, management)
    $historyDir = Join-Path $utilitiesModulesDir 'history'
    . (Join-Path $historyDir 'utilities-history.ps1')
    
    # Data utilities (encoding, date/time manipulation)
    $dataDir = Join-Path $utilitiesModulesDir 'data'
    . (Join-Path $dataDir 'utilities-encoding.ps1')
    . (Join-Path $dataDir 'utilities-datetime.ps1')
    
    # Filesystem utilities (path manipulation, directory operations)
    $filesystemDir = Join-Path $utilitiesModulesDir 'filesystem'
    . (Join-Path $filesystemDir 'utilities-filesystem.ps1')
}
