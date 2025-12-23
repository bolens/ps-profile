# ===============================================
# FileOperations.ps1
# File and directory operation utilities
# ===============================================

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

# Directory creation (Unix 'mkdir' equivalent with -p support)
<#
.SYNOPSIS
    Creates directories with Unix-like behavior.
.DESCRIPTION
    Creates new directories at the specified paths. Supports -p flag to create parent directories
    and accepts multiple directory names as arguments, similar to Unix mkdir.
.PARAMETER Path
    One or more directory paths to create.
.PARAMETER p
    Create parent directories as needed (equivalent to -Parent).
.PARAMETER Parent
    Create parent directories as needed.
.EXAMPLE
    mkdir -p core fragment path
    Creates multiple directories: core, fragment, and path.
.EXAMPLE
    mkdir -p parent/child/grandchild
    Creates the full directory path including parent directories.
#>
function New-Directory {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
        [string[]]$Path,

        [Alias('p')]
        [switch]$Parent
    )

    # Parse arguments manually to handle -p flag properly
    $createParents = $false
    $dirPaths = @()

    if ($Path) {
        foreach ($arg in $Path) {
            if ($arg -eq '-p' -or $arg -eq '--parent') {
                $createParents = $true
            }
            elseif (-not [string]::IsNullOrWhiteSpace($arg) -and $arg -notmatch '^-') {
                $dirPaths += $arg
            }
        }
    }

    # Also check the Parent switch parameter
    if ($Parent) {
        $createParents = $true
    }

    if ($dirPaths.Count -eq 0) {
        Write-Error "mkdir: missing operand"
        return
    }

    foreach ($dirPath in $dirPaths) {
        if ([string]::IsNullOrWhiteSpace($dirPath)) {
            continue
        }

        # Check if parent directory exists when -p is not used
        if (-not $createParents) {
            $parentDir = [System.IO.Path]::GetDirectoryName($dirPath)
            if ($parentDir -and -not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir)) {
                $errorMessage = "mkdir: cannot create directory '$dirPath': No such file or directory"
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.DirectoryNotFoundException]::new($errorMessage),
                    'DirectoryNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $dirPath
                )
                Write-Error $errorRecord -ErrorAction Continue
                throw $errorRecord
            }
        }

        try {
            if ($createParents) {
                # Create parent directories as needed
                $null = New-Item -ItemType Directory -Path $dirPath -Force -ErrorAction Stop
            }
            else {
                # Create only the specified directory (fail if parent doesn't exist)
                $null = New-Item -ItemType Directory -Path $dirPath -ErrorAction Stop
            }
        }
        catch [System.IO.DirectoryNotFoundException] {
            $errorMessage = "mkdir: cannot create directory '$dirPath': No such file or directory"
            Write-Error $errorMessage -ErrorAction Continue
            throw
        }
        catch [System.UnauthorizedAccessException] {
            $errorMessage = "mkdir: cannot create directory '$dirPath': Permission denied"
            Write-Error $errorMessage -ErrorAction Continue
            throw
        }
        catch [System.IO.IOException] {
            if ($_.Exception.Message -match 'already exists') {
                # Directory already exists - this is fine, continue silently
                continue
            }
            $errorMessage = "mkdir: cannot create directory '$dirPath': $($_.Exception.Message)"
            Write-Error $errorMessage -ErrorAction Continue
            throw
        }
        catch {
            $errorMessage = "mkdir: cannot create directory '$dirPath': $($_.Exception.Message)"
            Write-Error $errorMessage -ErrorAction Continue
            throw
        }
    }
}

# Override the built-in mkdir alias with our enhanced function
# Remove the built-in alias first, then set our function
if (Get-Alias -Name mkdir -ErrorAction SilentlyContinue) {
    Remove-Item -Path Alias:\mkdir -Force -ErrorAction SilentlyContinue
}
Set-Alias -Name mkdir -Value New-Directory -ErrorAction SilentlyContinue

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

