# ===============================================
# 66-dust.ps1
# Modern disk usage analyzer with dust
# ===============================================

# Dust aliases
# Requires: dust (https://github.com/bootandy/dust)

if (Get-Command dust -ErrorAction SilentlyContinue) {
    # Main dust command
    <#
    .SYNOPSIS
        Shows disk usage with dust.
    .DESCRIPTION
        Launches dust, a modern disk usage analyzer that provides an intuitive, interactive view of disk space usage. Displays directory sizes in a tree format sorted by size.
    #>
    Set-Alias -Name du -Value dust -Option AllScope -Force
    
    <#
    .SYNOPSIS
        Shows disk usage with dust.
    .DESCRIPTION
        Launches dust, a modern disk usage analyzer that provides an intuitive, interactive view of disk space usage. Displays directory sizes in a tree format sorted by size.
    #>
    Set-Alias -Name diskusage -Value dust -Option AllScope -Force
}
else {
    Write-Warning "dust not found. Install with: scoop install dust"
}
