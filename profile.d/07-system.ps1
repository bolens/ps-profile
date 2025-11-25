# ===============================================
# 07-system.ps1
# System utilities (shell-like helpers adapted for PowerShell)
# ===============================================
# Provides Unix-style command aliases and helper functions for common system operations.
# These functions wrap PowerShell cmdlets to provide familiar command names for users
# coming from Unix/Linux environments or who prefer shorter command names.

try {
    # Command location lookup (Unix 'which' equivalent)
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

    # Pattern search in files (Unix 'grep' equivalent)
    <#
    .SYNOPSIS
        Searches for patterns in files.
    .DESCRIPTION
        Searches for text patterns in files using Select-String.
    #>
    function Find-String {
        param([string]$Pattern, [string]$Path)
    
        if ([string]::IsNullOrWhiteSpace($Pattern)) {
            Write-Error "Pattern parameter is required"
            return
        }
    
        try {
            if ($Path) {
                if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
                    Write-Error "Path not found: $Path"
                    return
                }
                Select-String -Pattern $Pattern -Path $Path -ErrorAction Stop
            }
            else {
                $input | Select-String -Pattern $Pattern -ErrorAction Stop
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Error "Access denied reading path '$Path': $($_.Exception.Message)"
            throw
        }
        catch {
            Write-Error "Failed to search for pattern '$Pattern': $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name pgrep -Value Find-String -ErrorAction SilentlyContinue

    # Create/update file timestamps (Unix 'touch' equivalent)
    <#
    .SYNOPSIS
        Creates empty files or updates file timestamps.
    .DESCRIPTION
        Creates new empty files at the specified paths, or updates the last write time
        of existing files (Unix touch behavior).
    #>
    function New-EmptyFile {
        param(
            [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
            [string[]]$Path,

            [Alias('LiteralPath')]
            [string[]]$AdditionalPaths
        )

        $paths = @()

        if ($Path) {
            $paths += $Path
        }

        if ($AdditionalPaths) {
            $paths += $AdditionalPaths
        }

        if (-not $paths) {
            return
        }

        foreach ($path in $paths) {
            if (Test-Path -LiteralPath $path) {
                $existing = Get-Item -LiteralPath $path

                if ($existing -is [System.IO.FileInfo]) {
                    # Update last write time when touching an existing file (Unix touch behavior)
                    $existing.LastWriteTime = Get-Date
                    continue
                }

                throw "Path '$path' exists and is not a file"
            }

            try {
                $directory = [System.IO.Path]::GetDirectoryName($path)
                if ($directory -and -not (Test-Path -LiteralPath $directory)) {
                    throw "Directory '$directory' does not exist"
                }

                $fileStream = [System.IO.File]::Open($path, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::ReadWrite)
                $fileStream.Dispose()
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error "Access denied creating file '$path': $($_.Exception.Message)"
                throw
            }
            catch [System.IO.DirectoryNotFoundException] {
                Write-Error "Directory not found for path '$path': $($_.Exception.Message)"
                throw
            }
            catch [System.IO.IOException] {
                if ($_.Exception.Message -notmatch 'already exists') {
                    Write-Error "IO error creating file '$path': $($_.Exception.Message)"
                    throw
                }
            }
            catch {
                Write-Error "Unexpected error creating file '$path': $($_.Exception.Message)"
                throw
            }
        }
    }
    Set-Alias -Name touch -Value New-EmptyFile -ErrorAction SilentlyContinue

    # Directory creation (Unix 'mkdir' equivalent)
    # Note: mkdir is already a built-in PowerShell alias for New-Item, so we don't create a conflicting alias
    <#
    .SYNOPSIS
        Creates directories.
    .DESCRIPTION
        Creates new directories at the specified paths.
    #>
    function New-Directory { New-Item -ItemType Directory @args }
    # Note: mkdir is already a built-in alias, so we don't create a conflicting alias

    # File/directory removal (Unix 'rm' equivalent)
    # Note: rm is already a built-in PowerShell alias for Remove-Item
    <#
    .SYNOPSIS
        Removes files and directories.
    .DESCRIPTION
        Deletes files and directories recursively if needed.
    #>
    function Remove-ItemCustom { Remove-Item @args }
    # Note: rm is already a built-in alias, so we don't create a conflicting alias

    # File/directory copy (Unix 'cp' equivalent)
    # Note: cp is already a built-in PowerShell alias for Copy-Item
    <#
    .SYNOPSIS
        Copies files and directories.
    .DESCRIPTION
        Copies files and directories to specified destinations.
    #>
    function Copy-ItemCustom { Copy-Item @args }
    # Note: cp is already a built-in alias, so we don't create a conflicting alias

    # File/directory move/rename (Unix 'mv' equivalent)
    # Note: mv is already a built-in PowerShell alias for Move-Item
    <#
    .SYNOPSIS
        Moves files and directories.
    .DESCRIPTION
        Moves or renames files and directories.
    #>
    function Move-ItemCustom { Move-Item @args }
    # Note: mv is already a built-in alias, so we don't create a conflicting alias

    # Recursive file search (Unix 'find' equivalent)
    <#
    .SYNOPSIS
        Searches for files recursively.
    .DESCRIPTION
        Finds files by name pattern in the current directory and subdirectories.
    #>
    function Find-File {
        param([Parameter(ValueFromRemainingArguments = $true)] $FilterArgs)
    
        if (-not $FilterArgs -or $FilterArgs.Count -eq 0) {
            Write-Error "Find-File requires a filter pattern"
            return
        }
    
        try {
            Get-ChildItem -Recurse -Name -Filter $FilterArgs[0] -ErrorAction Stop
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning "Access denied to some directories. Results may be incomplete."
            # Try with ErrorAction SilentlyContinue to get partial results
            Get-ChildItem -Recurse -Name -Filter $FilterArgs[0] -ErrorAction SilentlyContinue
        }
        catch {
            Write-Error "Failed to search for files: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name search -Value Find-File -ErrorAction SilentlyContinue

    # Disk space usage (Unix 'df' equivalent)
    <#
    .SYNOPSIS
        Shows disk usage information.
    .DESCRIPTION
        Displays disk space usage (used, free, total) for all file system drives in GB.
    #>
    function Get-DiskUsage {
        try {
            Get-PSDrive -PSProvider FileSystem -ErrorAction Stop | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root
        }
        catch {
            Write-Error "Failed to get disk usage information: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name df -Value Get-DiskUsage -ErrorAction SilentlyContinue

    # Top processes by CPU (Unix 'top' equivalent, aliased as 'htop')
    <#
    .SYNOPSIS
        Shows top CPU-consuming processes.
    .DESCRIPTION
        Displays the top 10 processes sorted by CPU usage.
    #>
    function Get-TopProcesses {
        try {
            Get-Process -ErrorAction Stop | Sort-Object CPU -Descending | Select-Object -First 10
        }
        catch {
            Write-Error "Failed to get process information: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name htop -Value Get-TopProcesses -ErrorAction SilentlyContinue

    # Network ports and connections (Unix 'netstat' equivalent)
    <#
    .SYNOPSIS
        Shows network port information.
    .DESCRIPTION
        Displays active network connections and listening ports using netstat.
    #>
    function Get-NetworkPorts {
        try {
            if (-not (Get-Command netstat -ErrorAction SilentlyContinue)) {
                Write-Error "netstat command not found. This command is typically available on Windows and Unix systems."
                return
            }
            & netstat -an
        }
        catch {
            Write-Error "Failed to get network ports: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name ports -Value Get-NetworkPorts -ErrorAction SilentlyContinue

    # ptest equivalent
    <#
    .SYNOPSIS
        Tests network connectivity.
    .DESCRIPTION
        Tests connectivity to specified hosts using ping.
    #>
    function Test-NetworkConnection { Test-Connection @args }
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
    function Invoke-RestApi { Invoke-RestMethod @args }
    Set-Alias -Name rest -Value Invoke-RestApi -ErrorAction SilentlyContinue

    # web equivalent
    <#
    .SYNOPSIS
        Makes HTTP web requests.
    .DESCRIPTION
        Downloads content from web URLs or sends HTTP requests.
    #>
    function Invoke-WebRequestCustom { Invoke-WebRequest @args }
    Set-Alias -Name web -Value Invoke-WebRequestCustom -ErrorAction SilentlyContinue

    # unzip equivalent
    <#
    .SYNOPSIS
        Extracts ZIP archives.
    .DESCRIPTION
        Extracts files from ZIP archives to specified destinations.
    #>
    function Expand-ArchiveCustom { Expand-Archive @args }
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
    function Open-VSCode {
        $codePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
        try {
            if (-not (Test-Path $codePath)) {
                throw "VS Code not found at expected location: $codePath"
            }
            & $codePath $args
        }
        catch {
            Write-Error "Failed to open VS Code: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name code -Value Open-VSCode -ErrorAction SilentlyContinue

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
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: 07-system" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load system utilities fragment: $($_.Exception.Message)"
        }
    }
}
