# ===============================================
# mojo.ps1
# Mojo programming language tools
# ===============================================

# Mojo aliases and functions
# Requires: mojo (https://www.modular.com/mojo)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand mojo)) {
    # Mojo run
    <#
    .SYNOPSIS
        Runs Mojo programs.
    .DESCRIPTION
        Executes Mojo source files.
    #>
    function Invoke-MojoRun {
        [CmdletBinding()]
        param([string[]]$Files)
        
        & mojo run @Files
    }
    Set-Alias -Name mojo-run -Value Invoke-MojoRun -ErrorAction SilentlyContinue

    # Mojo build
    <#
    .SYNOPSIS
        Builds Mojo programs.
    .DESCRIPTION
        Compiles Mojo source files into executables.
    #>
    function Build-MojoProgram {
        [CmdletBinding()]
        param([string[]]$Files)
        
        & mojo build @Files
    }
    Set-Alias -Name mojo-build -Value Build-MojoProgram -ErrorAction SilentlyContinue

    # Mojo self-update - update mojo itself
    <#
    .SYNOPSIS
        Updates Mojo to the latest version.
    .DESCRIPTION
        Updates Mojo itself to the latest version using 'mojo update'.
    #>
    function Update-MojoSelf {
        [CmdletBinding()]
        param()
        
        & mojo update
    }
    Set-Alias -Name mojo-update -Value Update-MojoSelf -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'mojo' -InstallHint 'Install with: Follow instructions at https://www.modular.com/mojo'
}
