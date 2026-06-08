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
.EXAMPLE
    Invoke-MojoRun ./main.mojo
.PARAMETER Files
    Mojo source files to execute.

#>
    function Invoke-MojoRun {
        [CmdletBinding()]
        param([string[]]$Files)
        
        & mojo run @Files
    }
    Set-AgentModeAlias -Name 'mojo-run' -Target 'Invoke-MojoRun'
    # Mojo build
    <#
.SYNOPSIS
        Builds Mojo programs.
    .DESCRIPTION
        Compiles Mojo source files into executables.
.EXAMPLE
    Build-MojoProgram ./main.mojo
.PARAMETER Files
    Mojo source files to compile into executables.

#>
    function Build-MojoProgram {
        [CmdletBinding()]
        param([string[]]$Files)
        
        & mojo build @Files
    }
    Set-AgentModeAlias -Name 'mojo-build' -Target 'Build-MojoProgram'
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
    Set-AgentModeAlias -Name 'mojo-update' -Target 'Update-MojoSelf'
}
else {
    Invoke-MissingToolWarning -ToolName 'mojo' -Tool 'mojo'
}
