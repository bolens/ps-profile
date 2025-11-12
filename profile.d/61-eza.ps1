# ===============================================
# 61-eza.ps1
# Modern ls replacement with eza
# ===============================================

# Eza aliases for modern directory listing
# Requires: eza (https://github.com/eza-community/eza)

if (Test-HasCommand eza) {
    # Basic ls replacements
    <#
    .SYNOPSIS
        Lists directory contents using eza.
    .DESCRIPTION
        Replacement for ls command using eza for modern directory listing.
    #>
    function Get-ChildItemEza { eza @args }
    Set-Alias -Name ls -Value Get-ChildItemEza -ErrorAction SilentlyContinue

    <#
    .SYNOPSIS
        Lists directory contents using eza (short alias).
    .DESCRIPTION
        Short alias for eza directory listing.
    #>
    function Get-ChildItemEzaShort { eza @args }
    Set-Alias -Name l -Value Get-ChildItemEzaShort -ErrorAction SilentlyContinue

    # Long listing
    <#
    .SYNOPSIS
        Lists directory contents in long format using eza.
    .DESCRIPTION
        Shows detailed directory listing with permissions, sizes, and dates.
    #>
    function Get-ChildItemEzaLong { eza -l @args }
    Set-Alias -Name ll -Value Get-ChildItemEzaLong -ErrorAction SilentlyContinue

    <#
    .SYNOPSIS
        Lists all directory contents including hidden files using eza.
    .DESCRIPTION
        Shows all files including hidden ones in long format.
    #>
    function Get-ChildItemEzaAll { eza -la @args }
    Set-Alias -Name la -Value Get-ChildItemEzaAll -ErrorAction SilentlyContinue

    <#
    .SYNOPSIS
        Lists all directory contents in long format using eza.
    .DESCRIPTION
        Shows all files including hidden ones in detailed long format.
    #>
    function Get-ChildItemEzaAllLong { eza -la @args }
    Set-Alias -Name lla -Value Get-ChildItemEzaAllLong -ErrorAction SilentlyContinue

    # Tree view
    <#
    .SYNOPSIS
        Lists directory contents in tree format using eza.
    .DESCRIPTION
        Shows directory structure as a tree view.
    #>
    function Get-ChildItemEzaTree { eza --tree @args }
    Set-Alias -Name lt -Value Get-ChildItemEzaTree -ErrorAction SilentlyContinue

    <#
    .SYNOPSIS
        Lists all directory contents in tree format using eza.
    .DESCRIPTION
        Shows all files including hidden ones in tree format.
    #>
    function Get-ChildItemEzaTreeAll { eza --tree -a @args }
    Set-Alias -Name lta -Value Get-ChildItemEzaTreeAll -ErrorAction SilentlyContinue

    # With git status
    <#
    .SYNOPSIS
        Lists directory contents with git status using eza.
    .DESCRIPTION
        Shows files with git status indicators.
    #>
    function Get-ChildItemEzaGit { eza --git @args }
    Set-Alias -Name lg -Value Get-ChildItemEzaGit -ErrorAction SilentlyContinue

    <#
    .SYNOPSIS
        Lists directory contents in long format with git status using eza.
    .DESCRIPTION
        Shows detailed listing with git status indicators.
    #>
    function Get-ChildItemEzaLongGit { eza -l --git @args }
    Set-Alias -Name llg -Value Get-ChildItemEzaLongGit -ErrorAction SilentlyContinue

    # By size
    <#
    .SYNOPSIS
        Lists directory contents sorted by size using eza.
    .DESCRIPTION
        Shows files sorted by file size in descending order.
    #>
    function Get-ChildItemEzaBySize { eza -l -s size @args }
    Set-Alias -Name lS -Value Get-ChildItemEzaBySize -ErrorAction SilentlyContinue

    # By time
    <#
    .SYNOPSIS
        Lists directory contents sorted by modification time using eza.
    .DESCRIPTION
        Shows files sorted by modification time, newest first.
    #>
    function Get-ChildItemEzaByTime { eza -l -s modified @args }
    Set-Alias -Name ltime -Value Get-ChildItemEzaByTime -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'eza' -InstallHint 'Install with: scoop install eza'
}
