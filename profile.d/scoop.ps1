# ===============================================
# scoop.ps1
# Scoop Package Manager Helpers
# ===============================================
# Provides convenient aliases and wrapper functions for Scoop package manager operations.
# Tier: essential
# Dependencies: bootstrap, env

if (Test-CachedCommand scoop) {
    # Scoop tab completion module (enabled by default, can be disabled via PS_SCOOP_ENABLE_COMPLETION=0)
    # This resolves the "scoop checkup" warning about missing tab completion
    $enableCompletion = $true
    if ($env:PS_SCOOP_ENABLE_COMPLETION -eq '0' -or $env:PS_SCOOP_ENABLE_COMPLETION -eq 'false') {
        $enableCompletion = $false
    }
    
    if ($enableCompletion) {
        $scoopCompletionPath = $null
        
        # Try to use ScoopDetection module if available
        if (Get-Command Get-ScoopCompletionPath -ErrorAction SilentlyContinue) {
            $scoopCompletionPath = Get-ScoopCompletionPath
        }
        else {
            # Fallback: use scoop command to find installation path (most reliable)
            $scoopRoot = $null
            try {
                # Use 'scoop prefix scoop' to get the actual Scoop installation path
                # This works even for non-standard installations
                $scoopPrefixOutput = & scoop prefix scoop 2>&1
                if ($LASTEXITCODE -eq 0 -and $scoopPrefixOutput -and -not [string]::IsNullOrWhiteSpace($scoopPrefixOutput)) {
                    $scoopAppPath = $scoopPrefixOutput.ToString().Trim()
                    # The prefix points to the app directory, we need to go up to find the root
                    # Structure: <root>/apps/scoop/current -> we need <root>
                    if (Test-Path -LiteralPath $scoopAppPath -PathType Container -ErrorAction SilentlyContinue) {
                        # Try to find the root by going up from apps/scoop/current
                        $currentPath = $scoopAppPath
                        # Go up from current -> scoop -> apps -> root
                        for ($i = 0; $i -lt 3; $i++) {
                            $parentPath = Split-Path -Parent $currentPath
                            if ($parentPath -and (Test-Path -LiteralPath $parentPath -PathType Container -ErrorAction SilentlyContinue)) {
                                $currentPath = $parentPath
                            }
                            else {
                                break
                            }
                        }
                        # Verify this looks like a Scoop root (has apps directory)
                        $appsPath = Join-Path $currentPath 'apps'
                        if (Test-Path -LiteralPath $appsPath -PathType Container -ErrorAction SilentlyContinue) {
                            $scoopRoot = $currentPath
                        }
                    }
                }
            }
            catch {
                # scoop prefix failed, continue with other methods
            }
            
            # If scoop prefix didn't work, try environment variables
            if (-not $scoopRoot) {
                # Check global Scoop installation first
                if ($env:SCOOP_GLOBAL -and (Test-Path -LiteralPath $env:SCOOP_GLOBAL -PathType Container -ErrorAction SilentlyContinue)) {
                    $scoopRoot = $env:SCOOP_GLOBAL
                }
                # Check local Scoop installation
                elseif ($env:SCOOP -and (Test-Path -LiteralPath $env:SCOOP -PathType Container -ErrorAction SilentlyContinue)) {
                    $scoopRoot = $env:SCOOP
                }
                # Check default user location (cross-platform compatible)
                elseif ($env:USERPROFILE -or $env:HOME) {
                    $userHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
                    $defaultScoop = Join-Path $userHome 'scoop'
                    if (Test-Path -LiteralPath $defaultScoop -PathType Container -ErrorAction SilentlyContinue) {
                        $scoopRoot = $defaultScoop
                    }
                }
            }
            
            # Construct completion path from detected root
            if ($scoopRoot) {
                $completionPath = Join-Path $scoopRoot 'apps' 'scoop' 'current' 'supporting' 'completion' 'Scoop-Completion.psd1'
                if (Test-Path -LiteralPath $completionPath -PathType Leaf -ErrorAction SilentlyContinue) {
                    $scoopCompletionPath = $completionPath
                }
            }
        }
        
        if ($scoopCompletionPath) {
            try {
                Import-Module $scoopCompletionPath -ErrorAction SilentlyContinue
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to import Scoop completion module: $($_.Exception.Message)"
                }
            }
        }
    }

    # Scoop install
    <#
    .SYNOPSIS
        Installs packages using Scoop.
    .DESCRIPTION
        Installs one or more packages using the Scoop package manager.
    #>
    function Install-ScoopPackage { scoop install @args }
    Set-Alias -Name sinstall -Value Install-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop search
    <#
    .SYNOPSIS
        Searches for packages in Scoop.
    .DESCRIPTION
        Searches for available packages in Scoop repositories.
    #>
    function Find-ScoopPackage { scoop search @args }
    Set-Alias -Name ss -Value Find-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop update
    <#
    .SYNOPSIS
        Updates packages using Scoop.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    #>
    function Update-ScoopPackage { scoop update @args }
    Set-Alias -Name su -Value Update-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop update all
    <#
    .SYNOPSIS
        Updates all installed Scoop packages.
    .DESCRIPTION
        Updates all installed packages and Scoop itself.
    #>
    function Update-ScoopAll { scoop update * }
    Set-Alias -Name suu -Value Update-ScoopAll -ErrorAction SilentlyContinue

    # Scoop uninstall
    <#
    .SYNOPSIS
        Uninstalls packages using Scoop.
    .DESCRIPTION
        Removes installed packages from the system.
    #>
    function Uninstall-ScoopPackage { scoop uninstall @args }
    Set-Alias -Name sr -Value Uninstall-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop list
    <#
    .SYNOPSIS
        Lists installed Scoop packages.
    .DESCRIPTION
        Shows all packages currently installed via Scoop.
    #>
    function Get-ScoopPackage { scoop list @args }
    Set-Alias -Name slist -Value Get-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop info
    <#
    .SYNOPSIS
        Shows information about Scoop packages.
    .DESCRIPTION
        Displays detailed information about specified packages.
    #>
    function Get-ScoopPackageInfo { scoop info @args }
    Set-Alias -Name sh -Value Get-ScoopPackageInfo -ErrorAction SilentlyContinue

    # Scoop cleanup
    <#
    .SYNOPSIS
        Cleans up Scoop cache and old versions.
    .DESCRIPTION
        Removes old package versions and cleans the download cache.
    #>
    function Clear-ScoopCache { scoop cleanup *; scoop cache rm * }
    Set-Alias -Name scleanup -Value Clear-ScoopCache -ErrorAction SilentlyContinue

    # Scoop export - backup installed packages
    <#
    .SYNOPSIS
        Exports installed Scoop packages to a backup file.
    .DESCRIPTION
        Creates a JSON file containing all installed Scoop packages.
        This file can be used to restore packages on another system or after a reinstall.
    .PARAMETER Path
        Path to save the export file. Defaults to "scoopfile.json" in current directory.
    .EXAMPLE
        Export-ScoopPackages
        Exports packages to scoopfile.json in current directory.
    .EXAMPLE
        Export-ScoopPackages -Path "C:\backup\scoop-packages.json"
        Exports packages to a specific file.
    #>
    function Export-ScoopPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'scoopfile.json'
        )
        
        & scoop export | Out-File -FilePath $Path -Encoding UTF8
    }
    Set-Alias -Name scoopexport -Value Export-ScoopPackages -ErrorAction SilentlyContinue
    Set-Alias -Name scoopbackup -Value Export-ScoopPackages -ErrorAction SilentlyContinue

    # Scoop import - restore packages from backup
    <#
    .SYNOPSIS
        Restores Scoop packages from a backup file.
    .DESCRIPTION
        Installs all packages listed in a scoopfile.json file.
        This is useful for restoring packages after a system reinstall or on a new machine.
    .PARAMETER Path
        Path to the scoopfile.json file to import. Defaults to "scoopfile.json" in current directory.
    .EXAMPLE
        Import-ScoopPackages
        Restores packages from scoopfile.json in current directory.
    .EXAMPLE
        Import-ScoopPackages -Path "C:\backup\scoop-packages.json"
        Restores packages from a specific file.
    #>
    function Import-ScoopPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'scoopfile.json'
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Package file not found: $Path"
            return
        }
        
        & scoop import $Path
    }
    Set-Alias -Name scoopimport -Value Import-ScoopPackages -ErrorAction SilentlyContinue
    Set-Alias -Name scooprestore -Value Import-ScoopPackages -ErrorAction SilentlyContinue

    # Scoop repair - fix broken bucket Git references
    Set-AgentModeFunction -Name 'Repair-ScoopBuckets' -Body {
        <#
        .SYNOPSIS
            Fixes broken Git ORIG_HEAD references in Scoop bucket repositories.
        .DESCRIPTION
            Scans all Scoop buckets and fixes broken ORIG_HEAD references that can cause
            "fatal: update_ref failed for ref 'ORIG_HEAD'" errors during bucket updates.
            This function removes corrupted ORIG_HEAD files from bucket Git repositories.
            ORIG_HEAD is a temporary reference file that Git uses during operations like
            merge/rebase, and it's safe to remove if broken.
        .PARAMETER BucketName
            Optional. Name of a specific bucket to fix. If not provided, all buckets are checked.
        .EXAMPLE
            Repair-ScoopBuckets
            Fixes all broken ORIG_HEAD references in all Scoop buckets.
        .EXAMPLE
            Repair-ScoopBuckets -BucketName "versions"
            Fixes broken ORIG_HEAD reference in the "versions" bucket only.
        #>
        [CmdletBinding()]
        param(
            [string]$BucketName
        )

        # Collect all Scoop root directories (both global and user installations)
        # Scoop can have buckets in both locations, so we need to check both
        $scoopRoots = @()
        
        # Check global Scoop installation
        if ($env:SCOOP_GLOBAL -and (Test-Path -LiteralPath $env:SCOOP_GLOBAL)) {
            $scoopRoots += $env:SCOOP_GLOBAL
        }
        
        # Check local/user Scoop installation
        $userScoopPath = $null
        if ($env:SCOOP -and (Test-Path -LiteralPath $env:SCOOP)) {
            $userScoopPath = $env:SCOOP
        }
        elseif ($env:USERPROFILE) {
            $candidate = Join-Path $env:USERPROFILE 'scoop'
            if (Test-Path -LiteralPath $candidate) {
                $userScoopPath = $candidate
            }
        }
        
        # Add user installation if it exists and is different from global
        if ($userScoopPath -and $userScoopPath -notin $scoopRoots) {
            $scoopRoots += $userScoopPath
        }
        
        # Fallback: try Get-ScoopRoot if available (but don't rely on it exclusively)
        if ($scoopRoots.Count -eq 0 -and (Get-Command Get-ScoopRoot -ErrorAction SilentlyContinue)) {
            $detectedRoot = Get-ScoopRoot
            if ($detectedRoot -and $detectedRoot -notin $scoopRoots) {
                $scoopRoots += $detectedRoot
            }
        }

        if ($scoopRoots.Count -eq 0) {
            Write-Error "Scoop root directory not found. Is Scoop installed?"
            return
        }

        # Collect buckets from all Scoop installations
        $bucketsToProcess = @()
        $bucketsFound = @{}
        
        foreach ($scoopRoot in $scoopRoots) {
            $bucketsPath = Join-Path $scoopRoot 'buckets'
            if (Test-Path -LiteralPath $bucketsPath) {
                if ($BucketName) {
                    # Looking for a specific bucket
                    $bucketPath = Join-Path $bucketsPath $BucketName
                    if (Test-Path -LiteralPath $bucketPath) {
                        # Use the first found instance (or could collect all)
                        if (-not $bucketsFound.ContainsKey($BucketName)) {
                            $bucketsToProcess += $bucketPath
                            $bucketsFound[$BucketName] = $bucketPath
                        }
                    }
                }
                else {
                    # Collect all buckets from this installation
                    $buckets = Get-ChildItem -LiteralPath $bucketsPath -Directory -ErrorAction SilentlyContinue
                    foreach ($bucket in $buckets) {
                        $bucketName = $bucket.Name
                        # Only add if we haven't seen this bucket name yet (avoid duplicates)
                        if (-not $bucketsFound.ContainsKey($bucketName)) {
                            $bucketsToProcess += $bucket.FullName
                            $bucketsFound[$bucketName] = $bucket.FullName
                        }
                    }
                }
            }
            else {
                Write-Verbose "Buckets directory not found: ${bucketsPath} (skipping)"
            }
        }

        if ($BucketName -and $bucketsToProcess.Count -eq 0) {
            Write-Warning "Bucket '${BucketName}' not found in any Scoop installation"
            return
        }
        
        if ($bucketsToProcess.Count -eq 0) {
            Write-Warning "No buckets found in any Scoop installation"
            return
        }

        $fixedCount = 0
        $checkedCount = 0

        foreach ($bucketPath in $bucketsToProcess) {
            $bucketName = Split-Path -Leaf $bucketPath
            $gitDir = Join-Path $bucketPath '.git'
            $origHeadPath = Join-Path $gitDir 'ORIG_HEAD'

            # Check if this is a Git repository
            if (-not (Test-Path -LiteralPath $gitDir)) {
                Write-Verbose "Skipping ${bucketName} (not a Git repository)"
                continue
            }

            $checkedCount++

            # Check if ORIG_HEAD exists and try to fix it
            # ORIG_HEAD is a temporary reference file that Git uses during operations.
            # If it's broken or locked, we can safely remove it.
            if (Test-Path -LiteralPath $origHeadPath) {
                $removed = $false
                
                # First, try to validate if ORIG_HEAD is broken
                Push-Location $bucketPath
                try {
                    # Try to read the reference - if it fails, it's broken
                    $null = git rev-parse --verify ORIG_HEAD 2>&1 | Out-Null
                    $isBroken = ($LASTEXITCODE -ne 0)
                }
                catch {
                    $isBroken = $true
                }
                finally {
                    Pop-Location
                }

                # If broken or if we can't verify, try to remove it
                if ($isBroken) {
                    # Try to remove via Git first (cleaner, handles locks better)
                    Push-Location $bucketPath
                    try {
                        $null = git update-ref -d ORIG_HEAD 2>&1 | Out-Null
                        if ($LASTEXITCODE -eq 0) {
                            $removed = $true
                        }
                    }
                    catch {
                        # Git command failed, will try file deletion
                    }
                    finally {
                        Pop-Location
                    }

                    # If Git removal failed or file still exists, remove directly
                    if (-not $removed -and (Test-Path -LiteralPath $origHeadPath)) {
                        try {
                            # Remove read-only attribute if present
                            $file = Get-Item -LiteralPath $origHeadPath -Force -ErrorAction SilentlyContinue
                            if ($file) {
                                $file.Attributes = $file.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                            }
                            Remove-Item -LiteralPath $origHeadPath -Force -ErrorAction Stop
                            $removed = $true
                        }
                        catch {
                            Write-Warning "Failed to remove ORIG_HEAD from ${bucketName}: $($_.Exception.Message)"
                            Write-Warning "Path: ${origHeadPath}"
                            Write-Warning "Try running: Remove-Item -Path '${origHeadPath}' -Force"
                        }
                    }

                    if ($removed) {
                        Write-Host "Fixed: Removed broken ORIG_HEAD from ${bucketName}" -ForegroundColor Green
                        $fixedCount++
                    }
                }
                else {
                    Write-Verbose "ORIG_HEAD in ${bucketName} is valid"
                }
            }
            else {
                Write-Verbose "No ORIG_HEAD found in ${bucketName} (this is normal)"
            }
        }

        if ($checkedCount -eq 0) {
            Write-Warning "No Git repositories found in buckets directory"
        }
        elseif ($fixedCount -eq 0) {
            Write-Host "All checked buckets are healthy. No fixes needed." -ForegroundColor Green
        }
        else {
            Write-Host "Fixed ${fixedCount} of ${checkedCount} bucket(s)." -ForegroundColor Green
        }
    }
    Set-AgentModeAlias -Name 'scooprepair' -Target 'Repair-ScoopBuckets'
    Set-AgentModeAlias -Name 'fixscoop' -Target 'Repair-ScoopBuckets'
}
else {
    Write-MissingToolWarning -Tool 'Scoop' -InstallHint 'Install from: https://scoop.sh/'
}
