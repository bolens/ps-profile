# ===============================================
# EditorAliases.ps1
# Editor alias utilities
# ===============================================

# vim alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim.
.DESCRIPTION
    Launches Neovim text editor with the specified files.
#>
function Open-Neovim {
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        Invoke-WithWideEvent -OperationName 'editor.neovim.open' -Context @{
            args = $args
        } -ScriptBlock {
            if (-not (Test-CachedCommand 'nvim')) {
                throw "nvim command not found. Please install Neovim to use this function."
            }
            & nvim $args
        }
    }
    else {
        try {
            if (-not (Test-CachedCommand 'nvim')) {
                throw "nvim command not found. Please install Neovim to use this function."
            }
            & nvim $args
        }
        catch {
            Write-Error "Failed to open Neovim: $($_.Exception.Message)"
            throw
        }
    }
}
Set-AgentModeAlias -Name 'vim' -Target 'Open-Neovim'
# vi alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim (vi mode).
.DESCRIPTION
    Launches Neovim in vi compatibility mode with the specified files.
#>
function Open-NeovimVi {
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        Invoke-WithWideEvent -OperationName 'editor.neovim.open' -Context @{
            args = $args
        } -ScriptBlock {
            if (-not (Test-CachedCommand 'nvim')) {
                throw "nvim command not found. Please install Neovim to use this function."
            }
            & nvim $args
        }
    }
    else {
        try {
            if (-not (Test-CachedCommand 'nvim')) {
                throw "nvim command not found. Please install Neovim to use this function."
            }
            & nvim $args
        }
        catch {
            Write-Error "Failed to open Neovim: $($_.Exception.Message)"
            throw
        }
    }
}
Set-AgentModeAlias -Name 'vi' -Target 'Open-NeovimVi'