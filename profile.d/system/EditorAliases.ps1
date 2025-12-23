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
    try {
        if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
            throw "nvim command not found. Please install Neovim to use this function."
        }
        & nvim $args
    }
    catch {
        Write-Error "Failed to open Neovim: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name vim -Value Open-Neovim -ErrorAction SilentlyContinue

# vi alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim (vi mode).
.DESCRIPTION
    Launches Neovim in vi compatibility mode with the specified files.
#>
function Open-NeovimVi {
    try {
        if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
            throw "nvim command not found. Please install Neovim to use this function."
        }
        & nvim $args
    }
    catch {
        Write-Error "Failed to open Neovim: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name vi -Value Open-NeovimVi -ErrorAction SilentlyContinue

