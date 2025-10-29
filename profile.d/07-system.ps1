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
function which { Get-Command $args }

# pgrep equivalent
<#
.SYNOPSIS
    Searches for patterns in files.
.DESCRIPTION
    Searches for text patterns in files using Select-String.
#>
function pgrep { Select-String $args }

# touch equivalent
<#
.SYNOPSIS
    Creates empty files.
.DESCRIPTION
    Creates new empty files at the specified paths.
#>
function touch { New-Item -ItemType File $args }

# mkdir equivalent
<#
.SYNOPSIS
    Creates directories.
.DESCRIPTION
    Creates new directories at the specified paths.
#>
function mkdir { New-Item -ItemType Directory $args }

# rm equivalent
<#
.SYNOPSIS
    Removes files and directories.
.DESCRIPTION
    Deletes files and directories recursively if needed.
#>
function rm { Remove-Item $args }

# cp equivalent
<#
.SYNOPSIS
    Copies files and directories.
.DESCRIPTION
    Copies files and directories to specified destinations.
#>
function cp { Copy-Item $args }

# mv equivalent
<#
.SYNOPSIS
    Moves files and directories.
.DESCRIPTION
    Moves or renames files and directories.
#>
function mv { Move-Item $args }

# search equivalent
<#
.SYNOPSIS
    Searches for files recursively.
.DESCRIPTION
    Finds files by name in the current directory and subdirectories.
#>
function search { Get-ChildItem -Recurse -Name $args }

# df equivalent
<#
.SYNOPSIS
    Shows disk usage information.
.DESCRIPTION
    Displays disk space usage for all file system drives.
#>
function df { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root }

# top equivalent
<#
.SYNOPSIS
    Shows top CPU-consuming processes.
.DESCRIPTION
    Displays the top 10 processes sorted by CPU usage.
#>
function htop { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

# ports equivalent
<#
.SYNOPSIS
    Shows network port information.
.DESCRIPTION
    Displays active network connections and listening ports.
#>
function ports { netstat -an $args }

# ptest equivalent
<#
.SYNOPSIS
    Tests network connectivity.
.DESCRIPTION
    Tests connectivity to specified hosts using ping.
#>
function ptest { Test-Connection $args }

# dns equivalent
<#
.SYNOPSIS
    Resolves DNS names.
.DESCRIPTION
    Performs DNS lookups for hostnames or IP addresses.
#>
function dns { Resolve-DnsName $args }

# rest equivalent
<#
.SYNOPSIS
    Makes REST API calls.
.DESCRIPTION
    Sends HTTP requests to REST APIs and returns the response.
#>
function rest { Invoke-RestMethod $args }

# web equivalent
<#
.SYNOPSIS
    Makes HTTP web requests.
.DESCRIPTION
    Downloads content from web URLs or sends HTTP requests.
#>
function web { Invoke-WebRequest $args }

# unzip equivalent
<#
.SYNOPSIS
    Extracts ZIP archives.
.DESCRIPTION
    Extracts files from ZIP archives to specified destinations.
#>
function unzip { Expand-Archive $args }

# zip equivalent
<#
.SYNOPSIS
    Creates ZIP archives.
.DESCRIPTION
    Compresses files and directories into ZIP archives.
#>
function zip { Compress-Archive $args }

# code alias for VS Code
<#
.SYNOPSIS
    Opens files in Visual Studio Code.
.DESCRIPTION
    Launches Visual Studio Code with the specified files or directories.
#>
function code { & "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" $args }

# vim alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim.
.DESCRIPTION
    Launches Neovim text editor with the specified files.
#>
function vim { nvim $args }

# vi alias for neovim
<#
.SYNOPSIS
    Opens files in Neovim (vi mode).
.DESCRIPTION
    Launches Neovim in vi compatibility mode with the specified files.
#>
function vi { nvim $args }























