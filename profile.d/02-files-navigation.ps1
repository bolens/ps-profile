# ===============================================
# 02-files-navigation.ps1
# File navigation utilities
# ===============================================

# Lazy bulk initializer for file navigation helpers
<#
.SYNOPSIS
    Initializes file navigation utility functions on first use.
.DESCRIPTION
    Sets up all file navigation utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
if (-not (Test-Path "Function:\\Ensure-FileNavigation")) {
    function Ensure-FileNavigation {
        # Up directory
        function global:.. { Set-Location .. }
        # Up two directories
        function global:... { Set-Location ..\..\ }
        # Up three directories
        function global:.... { Set-Location ..\..\..\ }
        # Go to user's Home directory
        Set-Item -Path Function:~ -Value { Set-Location $env:USERPROFILE } -Force | Out-Null
        # Go to user's Desktop directory
        Set-Item -Path Function:Set-LocationDesktop -Value { Set-Location "$env:USERPROFILE\Desktop" } -Force | Out-Null
        Set-Alias -Name desktop -Value Set-LocationDesktop -ErrorAction SilentlyContinue
        # Go to user's Downloads directory
        Set-Item -Path Function:Set-LocationDownloads -Value { Set-Location "$env:USERPROFILE\Downloads" } -Force | Out-Null
        Set-Alias -Name downloads -Value Set-LocationDownloads -ErrorAction SilentlyContinue
        # Go to user's Documents directory
        Set-Item -Path Function:Set-LocationDocuments -Value { Set-Location "$env:USERPROFILE\Documents" } -Force | Out-Null
        Set-Alias -Name docs -Value Set-LocationDocuments -ErrorAction SilentlyContinue
    }
}

# Up one directory
<#
.SYNOPSIS
    Changes to the parent directory.
.DESCRIPTION
    Moves up one directory level in the file system.
#>
function .. { if (-not (Test-Path Function:\..)) { Ensure-FileNavigation }; return & (Get-Item Function:\.. -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Up two directories
<#
.SYNOPSIS
    Changes to the grandparent directory.
.DESCRIPTION
    Moves up two directory levels in the file system.
#>
function ... { if (-not (Test-Path Function:\...)) { Ensure-FileNavigation }; return & (Get-Item Function:\... -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Up three directories
<#
.SYNOPSIS
    Changes to the great-grandparent directory.
.DESCRIPTION
    Moves up three directory levels in the file system.
#>
function .... { if (-not (Test-Path Function:\....)) { Ensure-FileNavigation }; return & (Get-Item Function:\.... -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Go to user home directory
Set-Item -Path Function:\~ -Value { if (-not (Test-Path Function:\~)) { Ensure-FileNavigation }; return & (Get-Item Function:\~ -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null

# Go to Desktop directory
<#
.SYNOPSIS
    Changes to the Desktop directory.
.DESCRIPTION
    Navigates to the user's Desktop folder.
#>
function Set-LocationDesktop { if (-not (Test-Path Function:\Set-LocationDesktop)) { Ensure-FileNavigation }; return & (Get-Item Function:\Set-LocationDesktop -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name desktop -Value Set-LocationDesktop -ErrorAction SilentlyContinue

# Go to Downloads directory
<#
.SYNOPSIS
    Changes to the Downloads directory.
.DESCRIPTION
    Navigates to the user's Downloads folder.
#>
function Set-LocationDownloads { if (-not (Test-Path Function:\Set-LocationDownloads)) { Ensure-FileNavigation }; return & (Get-Item Function:\Set-LocationDownloads -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name downloads -Value Set-LocationDownloads -ErrorAction SilentlyContinue

# Go to Documents directory
<#
.SYNOPSIS
    Changes to the Documents directory.
.DESCRIPTION
    Navigates to the user's Documents folder.
#>
function Set-LocationDocuments { if (-not (Test-Path Function:\Set-LocationDocuments)) { Ensure-FileNavigation }; return & (Get-Item Function:\Set-LocationDocuments -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name docs -Value Set-LocationDocuments -ErrorAction SilentlyContinue
