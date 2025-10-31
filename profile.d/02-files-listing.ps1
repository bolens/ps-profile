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
        Set-Item -Path Function:ll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -la --icons --git @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Item -Path Function:la -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -la --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Item -Path Function:lx -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Item -Path Function:tree -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -T --icons @fileArgs } else { Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName } } -Force | Out-Null

        # bat wrapper
        Set-Item -Path Function:bat-cat -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if ($fileArgs) { if (Test-CachedCommand bat) { bat @fileArgs } else { Get-Content -LiteralPath @fileArgs | Out-Host } } else { if (Test-CachedCommand bat) { bat } else { $input | Out-Host } } } -Force | Out-Null
    }
}

# List files in a directory
<#
.SYNOPSIS
    Lists directory contents with details.
.DESCRIPTION
    Shows files and directories with permissions, sizes, and dates. Uses eza if available.
#>
function ll { if (-not (Test-Path Function:\ll)) { Ensure-FileListing }; return & (Get-Item Function:\ll -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# List all files including hidden
<#
.SYNOPSIS
    Lists all directory contents including hidden files.
.DESCRIPTION
    Shows all files and directories including hidden ones. Uses eza if available.
#>
function la { if (-not (Test-Path Function:\la)) { Ensure-FileListing }; return & (Get-Item Function:\la -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# List files excluding hidden
<#
.SYNOPSIS
    Lists directory contents excluding hidden files.
.DESCRIPTION
    Shows files and directories but excludes hidden ones. Uses eza if available.
#>
function lx { if (-not (Test-Path Function:\lx)) { Ensure-FileListing }; return & (Get-Item Function:\lx -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Display directory tree
<#
.SYNOPSIS
    Displays directory structure as a tree.
.DESCRIPTION
    Shows hierarchical directory structure. Uses eza if available.
#>
function tree { if (-not (Test-Path Function:\tree)) { Ensure-FileListing }; return & (Get-Item Function:\tree -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# cat with syntax highlighting (bat)
<#
.SYNOPSIS
    Displays file contents with syntax highlighting.
.DESCRIPTION
    Shows file contents with syntax highlighting using bat, or falls back to Get-Content.
#>
function bat-cat { if (-not (Test-Path Function:\bat-cat)) { Ensure-FileListing }; return & (Get-Item Function:\bat-cat -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
