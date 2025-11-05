# ===============================================
# 02-files-listing.ps1
# File listing utilities
# ===============================================

# Lazy bulk initializer for file listing helpers
<#
.SYNOPSIS
    Initializes file listing utility functions on first use.
.DESCRIPTION
    Sets up all file listing utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
if (-not (Test-Path "Function:\\Ensure-FileListing")) {
    function Ensure-FileListing {
        # Listing helpers (prefer eza when available)
        Set-Item -Path Function:Get-ChildItemDetailed -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza -la --icons --git @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name ll -Value Get-ChildItemDetailed -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-ChildItemAll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza -la --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name la -Value Get-ChildItemAll -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-ChildItemVisible -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name lx -Value Get-ChildItemVisible -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-DirectoryTree -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza -T --icons @fileArgs } else { Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName } } -Force | Out-Null
        Set-Alias -Name tree -Value Get-DirectoryTree -ErrorAction SilentlyContinue

        # bat wrapper
        Set-Item -Path Function:Show-FileContent -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if ($fileArgs) { if (Test-HasCommand bat) { bat @fileArgs } else { Get-Content -LiteralPath @fileArgs | Out-Host } } else { if (Test-HasCommand bat) { bat } else { $input | Out-Host } } } -Force | Out-Null
        Set-Alias -Name bat-cat -Value Show-FileContent -ErrorAction SilentlyContinue
    }
}

# List files in a directory
<#
.SYNOPSIS
    Lists directory contents with details.
.DESCRIPTION
    Shows files and directories with permissions, sizes, and dates. Uses eza if available.
#>
function Get-ChildItemDetailed { if (-not (Test-Path Function:\Get-ChildItemDetailed)) { Ensure-FileListing }; return & (Get-Item Function:\Get-ChildItemDetailed -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name ll -Value Get-ChildItemDetailed -ErrorAction SilentlyContinue

# List all files including hidden
<#
.SYNOPSIS
    Lists all directory contents including hidden files.
.DESCRIPTION
    Shows all files and directories including hidden ones. Uses eza if available.
#>
function Get-ChildItemAll { if (-not (Test-Path Function:\Get-ChildItemAll)) { Ensure-FileListing }; return & (Get-Item Function:\Get-ChildItemAll -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name la -Value Get-ChildItemAll -ErrorAction SilentlyContinue

# List files excluding hidden
<#
.SYNOPSIS
    Lists directory contents excluding hidden files.
.DESCRIPTION
    Shows files and directories but excludes hidden ones. Uses eza if available.
#>
function Get-ChildItemVisible { if (-not (Test-Path Function:\Get-ChildItemVisible)) { Ensure-FileListing }; return & (Get-Item Function:\Get-ChildItemVisible -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name lx -Value Get-ChildItemVisible -ErrorAction SilentlyContinue

# Display directory tree
<#
.SYNOPSIS
    Displays directory structure as a tree.
.DESCRIPTION
    Shows hierarchical directory structure. Uses eza if available.
#>
function Get-DirectoryTree { if (-not (Test-Path Function:\Get-DirectoryTree)) { Ensure-FileListing }; return & (Get-Item Function:\Get-DirectoryTree -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name tree -Value Get-DirectoryTree -ErrorAction SilentlyContinue

# cat with syntax highlighting (bat)
<#
.SYNOPSIS
    Displays file contents with syntax highlighting.
.DESCRIPTION
    Shows file contents with syntax highlighting using bat, or falls back to Get-Content.
#>
function Show-FileContent { if (-not (Test-Path Function:\Show-FileContent)) { Ensure-FileListing }; return & (Get-Item Function:\Show-FileContent -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name bat-cat -Value Show-FileContent -ErrorAction SilentlyContinue
