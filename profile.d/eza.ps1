# ===============================================
# eza.ps1
# Modern ls replacement with eza
# ===============================================

# Eza aliases for modern directory listing
# Requires: eza (https://github.com/eza-community/eza)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand eza)) {
    # Basic ls replacements
    <#
    .SYNOPSIS
        Lists directory contents using eza.
    .DESCRIPTION
        Replacement for ls command using eza for modern directory listing.
    #>
    function Get-ChildItemEza { eza @args }
    Set-AgentModeAlias -Name 'ls' -Target 'Get-ChildItemEza'
    <#
    .SYNOPSIS
        Lists directory contents using eza (short alias).
    .DESCRIPTION
        Short alias for eza directory listing.
    #>
    function Get-ChildItemEzaShort { eza @args }
    Set-AgentModeAlias -Name 'l' -Target 'Get-ChildItemEzaShort'
    # Long listing
    <#
    .SYNOPSIS
        Lists directory contents in long format using eza.
    .DESCRIPTION
        Shows detailed directory listing with permissions, sizes, and dates.
    #>
    function Get-ChildItemEzaLong { eza -l @args }
    Set-AgentModeAlias -Name 'll' -Target 'Get-ChildItemEzaLong'
    <#
    .SYNOPSIS
        Lists all directory contents including hidden files using eza.
    .DESCRIPTION
        Shows all files including hidden ones in long format.
    #>
    function Get-ChildItemEzaAll { eza -la @args }
    Set-AgentModeAlias -Name 'la' -Target 'Get-ChildItemEzaAll'
    <#
    .SYNOPSIS
        Lists all directory contents in long format using eza.
    .DESCRIPTION
        Shows all files including hidden ones in detailed long format.
    #>
    function Get-ChildItemEzaAllLong { eza -la @args }
    Set-AgentModeAlias -Name 'lla' -Target 'Get-ChildItemEzaAllLong'
    # Tree view
    <#
    .SYNOPSIS
        Lists directory contents in tree format using eza.
    .DESCRIPTION
        Shows directory structure as a tree view.
    #>
    function Get-ChildItemEzaTree { eza --tree @args }
    Set-AgentModeAlias -Name 'lt' -Target 'Get-ChildItemEzaTree'
    <#
    .SYNOPSIS
        Lists all directory contents in tree format using eza.
    .DESCRIPTION
        Shows all files including hidden ones in tree format.
    #>
    function Get-ChildItemEzaTreeAll { eza --tree -a @args }
    Set-AgentModeAlias -Name 'lta' -Target 'Get-ChildItemEzaTreeAll'
    # With git status
    <#
    .SYNOPSIS
        Lists directory contents with git status using eza.
    .DESCRIPTION
        Shows files with git status indicators.
    #>
    function Get-ChildItemEzaGit { eza --git @args }
    Set-AgentModeAlias -Name 'lg' -Target 'Get-ChildItemEzaGit'
    <#
    .SYNOPSIS
        Lists directory contents in long format with git status using eza.
    .DESCRIPTION
        Shows detailed listing with git status indicators.
    #>
    function Get-ChildItemEzaLongGit { eza -l --git @args }
    Set-AgentModeAlias -Name 'llg' -Target 'Get-ChildItemEzaLongGit'
    # By size
    <#
    .SYNOPSIS
        Lists directory contents sorted by size using eza.
    .DESCRIPTION
        Shows files sorted by file size in descending order.
    #>
    function Get-ChildItemEzaBySize { eza -l -s size @args }
    Set-AgentModeAlias -Name 'lS' -Target 'Get-ChildItemEzaBySize'
    # By time
    <#
    .SYNOPSIS
        Lists directory contents sorted by modification time using eza.
    .DESCRIPTION
        Shows files sorted by modification time, newest first.
    #>
    function Get-ChildItemEzaByTime { eza -l -s modified @args }
    Set-AgentModeAlias -Name 'ltime' -Target 'Get-ChildItemEzaByTime'
}
else {
    Invoke-MissingToolWarning -ToolName 'eza'
}
