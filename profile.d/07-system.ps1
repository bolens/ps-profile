# ===============================================
# 07-system.ps1
# System utilities (shell-like helpers adapted for PowerShell)
# ===============================================

# which equivalent
<#
.SYNOPSIS
    Shows information about commands.
.DESCRIPTION
    Displays information about PowerShell commands and their locations.
#>
function Get-CommandInfo {
    param([Parameter(ValueFromRemainingArguments = $true)] $CommandArgs)

    if (-not $CommandArgs) {
        return $null
    }

    try {
        return Get-Command @CommandArgs -ErrorAction SilentlyContinue
    }
    catch {
        return $null
    }
}
Set-Alias -Name which -Value Get-CommandInfo -ErrorAction SilentlyContinue

# pgrep equivalent
<#
.SYNOPSIS
    Searches for patterns in files.
.DESCRIPTION
    Searches for text patterns in files using Select-String.
#>
function Find-String {
    param([string]$Pattern, [string]$Path)
    if ($Path) {
        Select-String -Pattern $Pattern -Path $Path
    }
    else {
        $input | Select-String -Pattern $Pattern
    }
}
Set-Alias -Name pgrep -Value Find-String -ErrorAction SilentlyContinue

# touch equivalent
<#
.SYNOPSIS
    Creates empty files.
.DESCRIPTION
    Creates new empty files at the specified paths.
#>
function New-EmptyFile {
    param([Parameter(ValueFromRemainingArguments = $true)] $paths)

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            $existing = Get-Item -LiteralPath $path

            if ($existing -is [System.IO.FileInfo]) {
                # Update last write time when touching an existing file.
                $existing.LastWriteTime = Get-Date
                continue
            }

            throw "Path '$path' exists and is not a file"
        }

        try {
            New-Item -ItemType File -LiteralPath $path -Force | Out-Null
        }
        catch [System.IO.IOException] {
            if ($_.Exception.Message -notmatch 'already exists') {
                throw
            }
        }
    }
}
Set-Alias -Name touch -Value New-EmptyFile -ErrorAction SilentlyContinue

# mkdir equivalent - Note: mkdir is already a built-in alias for New-Item
# This function is kept for consistency but won't override the built-in
<#
.SYNOPSIS
    Creates directories.
.DESCRIPTION
    Creates new directories at the specified paths.
#>
function New-Directory { New-Item -ItemType Directory $args }
# Note: mkdir is already a built-in alias, so we don't create a conflicting alias

# rm equivalent - Note: rm is already a built-in alias for Remove-Item
# This function is kept for consistency but won't override the built-in
<#
.SYNOPSIS
    Removes files and directories.
.DESCRIPTION
    Deletes files and directories recursively if needed.
#>
function Remove-ItemCustom { Remove-Item $args }
# Note: rm is already a built-in alias, so we don't create a conflicting alias

# cp equivalent - Note: cp is already a built-in alias for Copy-Item
# This function is kept for consistency but won't override the built-in
<#
.SYNOPSIS
    Copies files and directories.
.DESCRIPTION
    Copies files and directories to specified destinations.
#>
function Copy-ItemCustom { Copy-Item $args }
# Note: cp is already a built-in alias, so we don't create a conflicting alias

# mv equivalent - Note: mv is already a built-in alias for Move-Item
# This function is kept for consistency but won't override the built-in
<#
.SYNOPSIS
    Moves files and directories.
.DESCRIPTION
    Moves or renames files and directories.
#>
function Move-ItemCustom { Move-Item $args }
# Note: mv is already a built-in alias, so we don't create a conflicting alias

# search equivalent
<#
.SYNOPSIS
    Searches for files recursively.
.DESCRIPTION
    Finds files by name in the current directory and subdirectories.
#>
function Find-File { Get-ChildItem -Recurse -Name -Filter $args[0] }
Set-Alias -Name search -Value Find-File -ErrorAction SilentlyContinue

# df equivalent
<#
.SYNOPSIS
    Shows disk usage information.
.DESCRIPTION
    Displays disk space usage for all file system drives.
#>
function Get-DiskUsage { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root }
Set-Alias -Name df -Value Get-DiskUsage -ErrorAction SilentlyContinue

# top equivalent
<#
.SYNOPSIS
    Shows top CPU-consuming processes.
.DESCRIPTION
    Displays the top 10 processes sorted by CPU usage.
#>
function Get-TopProcesses { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }
Set-Alias -Name htop -Value Get-TopProcesses -ErrorAction SilentlyContinue

# ports equivalent
<#
.SYNOPSIS
    Shows network port information.
.DESCRIPTION
    Displays active network connections and listening ports.
#>
function Get-NetworkPorts { netstat -an $args }
Set-Alias -Name ports -Value Get-NetworkPorts -ErrorAction SilentlyContinue

# ptest equivalent
<#
.SYNOPSIS
    Tests network connectivity.
.DESCRIPTION
    Tests connectivity to specified hosts using ping.
#>
function Test-NetworkConnection { Test-Connection $args }
Set-Alias -Name ptest -Value Test-NetworkConnection -ErrorAction SilentlyContinue

# dns equivalent
<#
.SYNOPSIS
    Resolves DNS names.
.DESCRIPTION
    Performs DNS lookups for hostnames or IP addresses.
#>
function Resolve-DnsNameCustom { Resolve-DnsName @args }
Set-Alias -Name dns -Value Resolve-DnsNameCustom -ErrorAction SilentlyContinue

# rest equivalent
<#
.SYNOPSIS
    Makes REST API calls.
.DESCRIPTION
    Sends HTTP requests to REST APIs and returns the response.
#>
function Invoke-RestApi { Invoke-RestMethod $args }
Set-Alias -Name rest -Value Invoke-RestApi -ErrorAction SilentlyContinue

# web equivalent
<#
.SYNOPSIS
    Makes HTTP web requests.
.DESCRIPTION
    Downloads content from web URLs or sends HTTP requests.
#>
function Invoke-WebRequestCustom { Invoke-WebRequest $args }
Set-Alias -Name web -Value Invoke-WebRequestCustom -ErrorAction SilentlyContinue

# unzip equivalent
<#
.SYNOPSIS
    Extracts ZIP archives.
.DESCRIPTION
    Extracts files from ZIP archives to specified destinations.
#>
function Expand-ArchiveCustom { Expand-Archive $args }
Set-Alias -Name unzip -Value Expand-ArchiveCustom -ErrorAction SilentlyContinue

# zip equivalent
<#
.SYNOPSIS
    Creates ZIP archives.
.DESCRIPTION
    Compresses files and directories into ZIP archives.
#>
function Compress-ArchiveCustom { & Compress-Archive @args }
Set-Alias -Name zip -Value Compress-ArchiveCustom -ErrorAction SilentlyContinue

# code alias for VS Code
<#
.SYNOPSIS
    Opens files in Visual Studio Code.
.DESCRIPTION
    Launches Visual Studio Code with the specified files or directories.
#>
function Open-VSCode { & "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" $args }
Set-Alias -Name code -Value Open-VSCode -ErrorAction SilentlyContinue

# vim alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim.
.DESCRIPTION
    Launches Neovim text editor with the specified files.
#>
function Open-Neovim { nvim $args }
Set-Alias -Name vim -Value Open-Neovim -ErrorAction SilentlyContinue

# vi alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim (vi mode).
.DESCRIPTION
    Launches Neovim in vi compatibility mode with the specified files.
#>
function Open-NeovimVi { nvim $args }
Set-Alias -Name vi -Value Open-NeovimVi -ErrorAction SilentlyContinue
