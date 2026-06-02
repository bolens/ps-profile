# ===============================================
# julia.ps1
# Julia package management
# ===============================================

# Julia Pkg aliases and functions
# Requires: julia (Julia - https://julialang.org/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand julia)) {
    # Julia Pkg update - update packages
    <#
    .SYNOPSIS
        Updates Julia packages.
    .DESCRIPTION
        Updates all packages in the current Julia environment to their latest versions.
        This is equivalent to running 'julia -e "using Pkg; Pkg.update()"'.
    #>
    function Update-JuliaPackages {
        [CmdletBinding()]
        param()
        
        & julia @('-e', 'using Pkg; Pkg.update()')
    }
    Set-AgentModeAlias -Name 'julia-update' -Target 'Update-JuliaPackages'
    # Julia Pkg status - check package status
    <#
    .SYNOPSIS
        Shows Julia package status.
    .DESCRIPTION
        Lists all installed packages and their versions.
        This is equivalent to running 'julia -e "using Pkg; Pkg.status()"'.
    #>
    function Get-JuliaPackages {
        [CmdletBinding()]
        param()
        
        & julia @('-e', 'using Pkg; Pkg.status()')
    }
    Set-AgentModeAlias -Name 'julia-status' -Target 'Get-JuliaPackages'
    # Julia Pkg add - add packages
    <#
    .SYNOPSIS
        Adds Julia packages.
    .DESCRIPTION
        Adds packages to the current Julia environment.
        This is equivalent to running 'julia -e "using Pkg; Pkg.add([\"package\"])"'.
    .PARAMETER Packages
        Package names to add.
    .EXAMPLE
        Add-JuliaPackage JSON
        Adds JSON package.
    #>
    function Add-JuliaPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        $packagesList = $Packages | ForEach-Object { "`"$_`"" } | Join-String -Separator ','
        & julia @('-e', "using Pkg; Pkg.add([$packagesList])")
    }
    Set-AgentModeAlias -Name 'julia-add' -Target 'Add-JuliaPackage'
    # Julia Pkg rm - remove packages
    <#
    .SYNOPSIS
        Removes Julia packages.
    .DESCRIPTION
        Removes packages from the current Julia environment.
        This is equivalent to running 'julia -e "using Pkg; Pkg.rm([\"package\"])"'.
    .PARAMETER Packages
        Package names to remove.
    .EXAMPLE
        Remove-JuliaPackage JSON
        Removes JSON package.
    #>
    function Remove-JuliaPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        $packagesList = $Packages | ForEach-Object { "`"$_`"" } | Join-String -Separator ','
        & julia @('-e', "using Pkg; Pkg.rm([$packagesList])")
    }
    Set-AgentModeAlias -Name 'julia-remove' -Target 'Remove-JuliaPackage'
}
else {
    Invoke-MissingToolWarning -ToolName 'julia'
}
