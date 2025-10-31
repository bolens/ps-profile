<#
# 76-smart-navigation.ps1

Smart directory navigation for PowerShell profile.
Tracks frequently used directories and provides quick jumping functionality.
#>

try {
    if ($null -ne (Get-Variable -Name 'SmartNavigationLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Initialize directory tracking
    if (-not $global:PSProfileDirectoryStats) {
        $global:PSProfileDirectoryStats = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
    }

    # Track directory changes
    <#
    .SYNOPSIS
        Tracks directory navigation for smart jumping.
    .DESCRIPTION
        Automatically tracks directory changes and maintains statistics
        for smart directory navigation features.
    #>
    function Update-DirectoryStats {
        param([string]$Path)

        if (-not $Path -or -not (Test-Path $Path)) {
            return
        }

        $normalizedPath = Resolve-Path $Path

        # Update visit count and timestamp
        if ($global:PSProfileDirectoryStats.ContainsKey($normalizedPath)) {
            $stats = $global:PSProfileDirectoryStats[$normalizedPath]
            $stats.VisitCount++
            $stats.LastVisited = Get-Date
            $stats.Score = [math]::Round($stats.Score * 0.9 + 10, 2)  # Decay existing score, add new points
        }
        else {
            $global:PSProfileDirectoryStats[$normalizedPath] = [PSCustomObject]@{
                Path         = $normalizedPath
                VisitCount   = 1
                FirstVisited = Get-Date
                LastVisited  = Get-Date
                Score        = 10
            }
        }

        # Keep only top 1000 directories to prevent memory bloat
        if ($global:PSProfileDirectoryStats.Count -gt 1000) {
            $toRemove = $global:PSProfileDirectoryStats.GetEnumerator() |
                Sort-Object { $_.Value.Score } |
                Select-Object -First ($global:PSProfileDirectoryStats.Count - 1000) |
                ForEach-Object { $_.Key }

            foreach ($key in $toRemove) {
                $global:PSProfileDirectoryStats.TryRemove($key, [ref]$null)
            }
        }
    }

    # Smart directory jumping
    <#
    .SYNOPSIS
        Jumps to frequently used directories.
    .DESCRIPTION
        Changes to the most frequently used directory matching the pattern.
        Uses fuzzy matching and scoring based on visit frequency and recency.
    .PARAMETER Pattern
        Pattern to match against directory paths.
    #>
    function Jump-Directory {
        param([string]$Pattern)

        if (-not $Pattern) {
            Write-Warning "Please provide a directory pattern to jump to."
            return
        }

        if ($global:PSProfileDirectoryStats.Count -eq 0) {
            Write-Host "No directory history available. Start navigating to build history."
            return
        }

        # Find matching directories
        $matchingDirs = $global:PSProfileDirectoryStats.GetEnumerator() | Where-Object {
            $_.Key -like "*$Pattern*" -or
            (Split-Path $_.Key -Leaf) -like "*$Pattern*"
        } | Sort-Object {
            # Sort by score (combination of frequency and recency)
            $daysSinceLastVisit = ((Get-Date) - $_.Value.LastVisited).TotalDays
            $recencyBonus = [math]::Max(0, 10 - $daysSinceLastVisit)
            $_.Value.Score + $recencyBonus
        } -Descending

        if ($matchingDirs.Count -eq 0) {
            Write-Warning "No directories found matching pattern: $Pattern"
            return
        }

        $targetDir = $matchingDirs[0].Key

        try {
            Set-Location $targetDir
            Update-DirectoryStats $targetDir
            Write-Host "Jumped to: $targetDir" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to jump to directory: $targetDir"
        }
    }

    # Quick jump alias
    <#
    .SYNOPSIS
        Quick directory jumping alias.
    .DESCRIPTION
        Alias for Jump-Directory for quick navigation.
    #>
    function j { Jump-Directory @args }

    # List frequently used directories
    <#
    .SYNOPSIS
        Lists frequently used directories.
    .DESCRIPTION
        Shows the most frequently visited directories with statistics.
    .PARAMETER Count
        Number of directories to show (default: 10).
    .PARAMETER Pattern
        Filter directories by pattern.
    #>
    function Show-FrequentDirectories {
        param(
            [int]$Count = 10,
            [string]$Pattern
        )

        if ($global:PSProfileDirectoryStats.Count -eq 0) {
            Write-Host "No directory history available."
            return
        }

        Write-Host "📁 Frequent Directories" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan

        $directories = $global:PSProfileDirectoryStats.GetEnumerator()

        # Apply pattern filter if provided
        if ($Pattern) {
            $directories = $directories | Where-Object {
                $_.Key -like "*$Pattern*" -or
                (Split-Path $_.Key -Leaf) -like "*$Pattern*"
            }
        }

        $topDirs = $directories | Sort-Object {
            $daysSinceLastVisit = ((Get-Date) - $_.Value.LastVisited).TotalDays
            $recencyBonus = [math]::Max(0, 10 - $daysSinceLastVisit)
            $_.Value.Score + $recencyBonus
        } -Descending | Select-Object -First $Count

        if ($topDirs.Count -eq 0) {
            Write-Host "No directories found matching pattern: $Pattern"
            return
        }

        $topDirs | ForEach-Object -Begin { $i = 1 } -Process {
            $stats = $_.Value
            $dirName = Split-Path $_.Key -Leaf
            $parentPath = Split-Path $_.Key -Parent
            $daysSinceVisit = [math]::Round(((Get-Date) - $stats.LastVisited).TotalDays, 1)

            Write-Host ("{0,2}. {1,-20} ({2} visits, {3} days ago)" -f $i, $dirName, $stats.VisitCount, $daysSinceVisit)
            if ($parentPath) {
                Write-Host ("    {0}" -f $parentPath) -ForegroundColor Gray
            }
            $i++
        }
    }

    # Directory bookmarks
    <#
    .SYNOPSIS
        Creates a directory bookmark.
    .DESCRIPTION
        Saves the current directory as a named bookmark for quick access.
    .PARAMETER Name
        Name for the bookmark.
    .PARAMETER Path
        Directory path to bookmark (defaults to current directory).
    #>
    function Add-DirectoryBookmark {
        param(
            [Parameter(Mandatory)]
            [string]$Name,
            [string]$Path = (Get-Location)
        )

        if (-not (Test-Path $Path)) {
            Write-Warning "Directory does not exist: $Path"
            return
        }

        $normalizedPath = Resolve-Path $Path

        if (-not $global:PSProfileDirectoryBookmarks) {
            $global:PSProfileDirectoryBookmarks = @{}
        }

        $global:PSProfileDirectoryBookmarks[$Name] = $normalizedPath
        Write-Host "Bookmarked '$Name' -> $normalizedPath" -ForegroundColor Green
    }

    <#
    .SYNOPSIS
        Jumps to a bookmarked directory.
    .DESCRIPTION
        Changes to a previously bookmarked directory.
    .PARAMETER Name
        Name of the bookmark to jump to.
    #>
    function Get-DirectoryBookmark {
        param([string]$Name)

        if (-not $global:PSProfileDirectoryBookmarks -or -not $global:PSProfileDirectoryBookmarks.ContainsKey($Name)) {
            Write-Warning "Bookmark not found: $Name"
            Write-Host "Available bookmarks:" -ForegroundColor Cyan
            if ($global:PSProfileDirectoryBookmarks) {
                $global:PSProfileDirectoryBookmarks.GetEnumerator() | ForEach-Object {
                    Write-Host "  $($_.Key) -> $($_.Value)" -ForegroundColor Gray
                }
            }
            return
        }

        $targetPath = $global:PSProfileDirectoryBookmarks[$Name]

        if (-not (Test-Path $targetPath)) {
            Write-Warning "Bookmarked directory no longer exists: $targetPath"
            return
        }

        try {
            Set-Location $targetPath
            Update-DirectoryStats $targetPath
            Write-Host "Jumped to bookmark '$Name': $targetPath" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to jump to bookmarked directory: $targetPath"
        }
    }

    <#
    .SYNOPSIS
        Lists all directory bookmarks.
    .DESCRIPTION
        Shows all saved directory bookmarks.
    #>
    function Show-DirectoryBookmarks {
        Write-Host "🔖 Directory Bookmarks" -ForegroundColor Yellow
        Write-Host "=====================" -ForegroundColor Yellow

        if (-not $global:PSProfileDirectoryBookmarks -or $global:PSProfileDirectoryBookmarks.Count -eq 0) {
            Write-Host "No bookmarks saved yet."
            Write-Host "Use 'Add-DirectoryBookmark -Name <name>' to create bookmarks."
            return
        }

        $global:PSProfileDirectoryBookmarks.GetEnumerator() | Sort-Object Name | ForEach-Object {
            $exists = Test-Path $_.Value
            $status = if ($exists) { "✓" } else { "✗" }
            $color = if ($exists) { "Green" } else { "Red" }
            Write-Host ("{0} {1,-15} -> {2}" -f $status, $_.Key, $_.Value) -ForegroundColor $color
        }
    }

    <#
    .SYNOPSIS
        Removes a directory bookmark.
    .DESCRIPTION
        Deletes a saved directory bookmark.
    .PARAMETER Name
        Name of the bookmark to remove.
    #>
    function Remove-DirectoryBookmark {
        param([Parameter(Mandatory)][string]$Name)

        if (-not $global:PSProfileDirectoryBookmarks -or -not $global:PSProfileDirectoryBookmarks.ContainsKey($Name)) {
            Write-Warning "Bookmark not found: $Name"
            return
        }

        $global:PSProfileDirectoryBookmarks.Remove($Name)
        Write-Host "Removed bookmark: $Name" -ForegroundColor Yellow
    }

    # Smart back/forward navigation
    <#
    .SYNOPSIS
        Goes back to the previous directory.
    .DESCRIPTION
        Maintains a navigation history and allows going back to previous directories.
    #>
    function Set-LocationBack {
        if (-not $global:PSProfileNavigationHistory) {
            $global:PSProfileNavigationHistory = [System.Collections.Generic.Stack[string]]::new()
        }

        if (-not $global:PSProfileNavigationFuture) {
            $global:PSProfileNavigationFuture = [System.Collections.Generic.Stack[string]]::new()
        }

        if ($global:PSProfileNavigationHistory.Count -gt 0) {
            $currentDir = Get-Location
            $global:PSProfileNavigationFuture.Push($currentDir.Path)

            $previousDir = $global:PSProfileNavigationHistory.Pop()
            Set-Location $previousDir
            Update-DirectoryStats $previousDir
            Write-Host "Back to: $previousDir" -ForegroundColor Blue
        }
        else {
            Write-Warning "No previous directory in navigation history."
        }
    }

    <#
    .SYNOPSIS
        Goes forward in the navigation history.
    .DESCRIPTION
        Moves forward in the directory navigation history.
    #>
    function Set-LocationForward {
        if (-not $global:PSProfileNavigationFuture) {
            $global:PSProfileNavigationFuture = [System.Collections.Generic.Stack[string]]::new()
        }

        if ($global:PSProfileNavigationFuture.Count -gt 0) {
            $currentDir = Get-Location
            $global:PSProfileNavigationHistory.Push($currentDir.Path)

            $nextDir = $global:PSProfileNavigationFuture.Pop()
            Set-Location $nextDir
            Update-DirectoryStats $nextDir
            Write-Host "Forward to: $nextDir" -ForegroundColor Blue
        }
        else {
            Write-Warning "No forward directory in navigation history."
        }
    }

    # Enhanced cd function that tracks navigation
    <#
    .SYNOPSIS
        Enhanced change directory with navigation tracking.
    .DESCRIPTION
        Changes directory and tracks navigation history for back/forward functionality.
    #>
    function Set-LocationTracked {
        param(
            [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
            [string]$Path
        )

        if (-not $Path) {
            # No path provided, go to home directory
            $Path = $HOME
        }

        # Initialize navigation stacks if needed
        if (-not $global:PSProfileNavigationHistory) {
            $global:PSProfileNavigationHistory = [System.Collections.Generic.Stack[string]]::new()
        }
        if (-not $global:PSProfileNavigationFuture) {
            $global:PSProfileNavigationFuture = [System.Collections.Generic.Stack[string]]::new()
        }

        $currentDir = Get-Location

        try {
            # Handle special paths
            switch -Regex ($Path) {
                '^-$' {
                    # Go back to previous directory
                    Set-LocationBack
                    return
                }
                '^\+$' {
                    # Go forward
                    Set-LocationForward
                    return
                }
                '^~$' {
                    # Go to home
                    $Path = $HOME
                }
            }

            # Try to resolve the path
            if (Test-Path $Path) {
                $resolvedPath = Resolve-Path $Path
            }
            elseif ($Path -match '^~') {
                # Handle ~ expansion
                $resolvedPath = $Path -replace '^~', $HOME
            }
            else {
                # Let Set-Location handle it (might be relative path)
                $resolvedPath = $Path
            }

            # Change directory
            Set-Location $resolvedPath

            # Track navigation (only if we're actually changing directories)
            $newDir = Get-Location
            if ($newDir.Path -ne $currentDir.Path) {
                $global:PSProfileNavigationHistory.Push($currentDir.Path)
                # Clear forward history when going to a new place
                $global:PSProfileNavigationFuture.Clear()
                Update-DirectoryStats $newDir.Path
            }
        }
        catch {
            Write-Warning "Failed to change directory: $($_.Exception.Message)"
        }
    }

    # Override built-in cd and Set-Location
    Set-Alias -Name cd -Value Set-LocationTracked -Option AllScope -ErrorAction SilentlyContinue
    Set-Alias -Name c -Value Set-LocationTracked -ErrorAction SilentlyContinue

    # Quick navigation aliases
    Set-Alias -Name b -Value Set-LocationBack -ErrorAction SilentlyContinue
    Set-Alias -Name f -Value Set-LocationForward -ErrorAction SilentlyContinue
    Set-Alias -Name bm -Value Show-DirectoryBookmarks -ErrorAction SilentlyContinue

    # Initialize navigation tracking for current directory
    Update-DirectoryStats (Get-Location)

    Set-Variable -Name 'SmartNavigationLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Smart navigation fragment failed: $($_.Exception.Message)" }
}
