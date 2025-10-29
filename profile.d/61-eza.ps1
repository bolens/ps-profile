# ===============================================
# 61-eza.ps1
# Modern ls replacement with eza
# ===============================================

# Eza aliases for modern directory listing
# Requires: eza (https://github.com/eza-community/eza)

if (Get-Command eza -ErrorAction SilentlyContinue) {
    # Basic ls replacements
    <#
    .SYNOPSIS
        Lists directory contents using eza.
    .DESCRIPTION
        Replacement for ls command using eza for modern directory listing.
    #>
    function ls { eza @args }

    <#
    .SYNOPSIS
        Lists directory contents using eza (short alias).
    .DESCRIPTION
        Short alias for eza directory listing.
    #>
    function l { eza @args }

    # Long listing
    <#
    .SYNOPSIS
        Lists directory contents in long format using eza.
    .DESCRIPTION
        Shows detailed directory listing with permissions, sizes, and dates.
    #>
    function ll { eza -l @args }

    <#
    .SYNOPSIS
        Lists all directory contents including hidden files using eza.
    .DESCRIPTION
        Shows all files including hidden ones in long format.
    #>
    function la { eza -la @args }

    <#
    .SYNOPSIS
        Lists all directory contents in long format using eza.
    .DESCRIPTION
        Shows all files including hidden ones in detailed long format.
    #>
    function lla { eza -la @args }

    # Tree view
    <#
    .SYNOPSIS
        Lists directory contents in tree format using eza.
    .DESCRIPTION
        Shows directory structure as a tree view.
    #>
    function lt { eza --tree @args }

    <#
    .SYNOPSIS
        Lists all directory contents in tree format using eza.
    .DESCRIPTION
        Shows all files including hidden ones in tree format.
    #>
    function lta { eza --tree -a @args }

    # With git status
    <#
    .SYNOPSIS
        Lists directory contents with git status using eza.
    .DESCRIPTION
        Shows files with git status indicators.
    #>
    function lg { eza --git @args }

    <#
    .SYNOPSIS
        Lists directory contents in long format with git status using eza.
    .DESCRIPTION
        Shows detailed listing with git status indicators.
    #>
    function llg { eza -l --git @args }

    # By size
    <#
    .SYNOPSIS
        Lists directory contents sorted by size using eza.
    .DESCRIPTION
        Shows files sorted by file size in descending order.
    #>
    function lS { eza -l -s size @args }

    # By time
    <#
    .SYNOPSIS
        Lists directory contents sorted by modification time using eza.
    .DESCRIPTION
        Shows files sorted by modification time, newest first.
    #>
    function ltime { eza -l -s modified @args }
}
else {
    Write-Warning "eza not found. Install with: scoop install eza"
}


















