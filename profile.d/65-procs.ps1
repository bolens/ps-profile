# ===============================================
# 65-procs.ps1
# Modern process viewer with procs
# ===============================================

# Procs aliases
# Requires: procs (https://github.com/dalance/procs)

if (Get-Command procs -ErrorAction SilentlyContinue) {
    # Main procs command
    <#
    .SYNOPSIS
        Lists processes with procs.
    .DESCRIPTION
        Launches procs, a modern replacement for ps that provides a faster, more user-friendly process viewer. Displays running processes with colorized output and improved formatting.
    #>
    Set-Alias -Name ps -Value procs -Option AllScope -Force
    
    <#
    .SYNOPSIS
        Searches processes with procs.
    .DESCRIPTION
        Launches procs with search capabilities, allowing you to filter and search through running processes. Uses procs as a modern replacement for ps with enhanced search functionality.
    #>
    Set-Alias -Name psgrep -Value procs -Option AllScope -Force
}
else {
    Write-Warning "procs not found. Install with: scoop install procs"
}
