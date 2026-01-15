# ===============================================
# CommandCache.ps1
# Command availability caching utilities
# ===============================================

<#
.SYNOPSIS
    Tests command availability with a short-lived in-memory cache.
.DESCRIPTION
    RECOMMENDED: This is the preferred function for command detection.
    Provides cached command availability checks to avoid repeated lookups.
    Cache entries expire after the specified number of minutes.
    
    This function implements the core command detection logic directly,
    avoiding circular dependencies with Test-HasCommand.
.PARAMETER Name
    The name of the command to check.
.PARAMETER CacheTTLMinutes
    Cache duration in minutes. Defaults to 5 minutes.
    Use 0 or 1 for immediate lookups (minimal caching).
.OUTPUTS
    System.Boolean
.EXAMPLE
    if (Test-CachedCommand -Name 'git') {
        # Git is available
    }
.NOTES
    This is the recommended function for command detection in new code.
    It provides better performance than Test-HasCommand through caching.
#>
function global:Test-CachedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [ValidateRange(0, 1440)]
        [int]$CacheTTLMinutes = 5
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    $normalizedName = $Name.Trim()

    # Check assumed commands first (bypasses actual command lookup for optional tools)
    if ($global:AssumedAvailableCommands -and $global:AssumedAvailableCommands.ContainsKey($normalizedName)) {
        return $true
    }

    $cacheKey = $normalizedName.ToLowerInvariant()
    $now = Get-Date

    # Check cache for existing entry that hasn't expired (if caching enabled)
    if ($CacheTTLMinutes -gt 0 -and $global:TestCachedCommandCache.ContainsKey($cacheKey)) {
        $entry = [pscustomobject]$global:TestCachedCommandCache[$cacheKey]
        if ($entry -and $entry.Expires -gt $now) {
            return [bool]$entry.Result
        }
    }

    # Cache miss or expired: perform actual command lookup
    # Core implementation (extracted from Test-HasCommand to avoid circular dependency)
    $result = $false

    # Check function provider first (avoids triggering module autoload which can be slow)
    # Test both local and global scopes to catch functions defined in either location
    $functionPaths = @(
        "Function:\$normalizedName",
        "Function:\global:$normalizedName"
    )

    foreach ($path in $functionPaths) {
        try {
            if ($path -and (Test-Path -LiteralPath $path)) {
                $result = $true
                break
            }
        }
        catch {
        }
    }

    if (-not $result) {
        # Check alias provider
        $aliasPaths = @(
            "Alias:\$normalizedName",
            "Alias:\global:$normalizedName"
        )

        foreach ($path in $aliasPaths) {
            try {
                if ($path -and (Test-Path -LiteralPath $path)) {
                    $result = $true
                    break
                }
            }
            catch {
            }
        }
    }

    if (-not $result) {
        # Fallback to Get-Command
        $command = Get-Command -Name $normalizedName -ErrorAction SilentlyContinue
        $result = $null -ne $command
        
        # If still not found and Scoop might be involved, check Scoop app directories
        # This handles cases where Scoop installed an app but shims weren't created
        if (-not $result) {
            $scoopLocal = if ($env:SCOOP) { $env:SCOOP } elseif ($env:USERPROFILE) { "$env:USERPROFILE\scoop" } else { $null }
            $scoopGlobal = $env:SCOOP_GLOBAL
            
            $extensions = @('.cmd', '.exe', '.bat')
            $scoopPaths = @()
            
            if ($scoopLocal -and (Test-Path -LiteralPath $scoopLocal -PathType Container)) {
                $scoopPaths += $scoopLocal
            }
            if ($scoopGlobal -and (Test-Path -LiteralPath $scoopGlobal -PathType Container)) {
                $scoopPaths += $scoopGlobal
            }
            
            foreach ($scoopRoot in $scoopPaths) {
                $appsPath = Join-Path $scoopRoot 'apps'
                if (Test-Path -LiteralPath $appsPath -PathType Container) {
                    # Check common app bin directories for the command
                    # Check known app locations first (e.g., ruby for gem, ridk), then scan others
                    $knownApps = @()
                    if ($normalizedName -eq 'gem' -or $normalizedName -eq 'ruby' -or $normalizedName -eq 'ridk') {
                        $knownApps += 'ruby'
                    }
                    
                    # Check known apps first
                    foreach ($appName in $knownApps) {
                        $appPath = Join-Path $appsPath $appName
                        if (Test-Path -LiteralPath $appPath -PathType Container) {
                            $binPath = Join-Path $appPath 'current\bin'
                            if (Test-Path -LiteralPath $binPath -PathType Container) {
                                foreach ($ext in $extensions) {
                                    $cmdPath = Join-Path $binPath "$normalizedName$ext"
                                    if (Test-Path -LiteralPath $cmdPath) {
                                        $result = $true
                                        break
                                    }
                                }
                                if ($result) { break }
                            }
                        }
                    }
                    
                    # If not found in known apps, scan other apps (limit to avoid performance issues)
                    if (-not $result) {
                        $apps = Get-ChildItem -LiteralPath $appsPath -Directory -ErrorAction SilentlyContinue | 
                        Where-Object { $knownApps -notcontains $_.Name } | 
                        Select-Object -First 20
                        foreach ($app in $apps) {
                            $binPath = Join-Path $app.FullName 'current\bin'
                            if (Test-Path -LiteralPath $binPath -PathType Container) {
                                foreach ($ext in $extensions) {
                                    $cmdPath = Join-Path $binPath "$normalizedName$ext"
                                    if (Test-Path -LiteralPath $cmdPath) {
                                        $result = $true
                                        break
                                    }
                                }
                                if ($result) { break }
                            }
                        }
                    }
                    
                    # Also check for gem-installed executables (e.g., pod from cocoapods)
                    # Check Ruby's bin directory and user gem directories for any command
                    # This handles commands installed via gem (like pod, bundler, etc.)
                    if (-not $result) {
                        # Check if Ruby is installed
                        $rubyAppPath = Join-Path $appsPath 'ruby'
                        if (Test-Path -LiteralPath $rubyAppPath -PathType Container) {
                            $rubyBinPath = Join-Path $rubyAppPath 'current\bin'
                            if (Test-Path -LiteralPath $rubyBinPath -PathType Container) {
                                # Check Ruby bin directory (where gem-installed executables go)
                                foreach ($ext in $extensions) {
                                    $cmdPath = Join-Path $rubyBinPath "$normalizedName$ext"
                                    if (Test-Path -LiteralPath $cmdPath) {
                                        $result = $true
                                        break
                                    }
                                }
                                
                                # Check user gem directories
                                # Ruby uses ~/.local/share/gem/ruby/<version>/bin on Windows (or ~/.gem/ruby/<version>/bin)
                                if (-not $result -and $env:USERPROFILE) {
                                    $userGemPaths = @(
                                        Join-Path $env:USERPROFILE '.local\share\gem\ruby',
                                        Join-Path $env:USERPROFILE '.gem\ruby'
                                    )
                                    
                                    foreach ($userGemBase in $userGemPaths) {
                                        if (Test-Path -LiteralPath $userGemBase -PathType Container) {
                                            $versionDirs = Get-ChildItem -LiteralPath $userGemBase -Directory -ErrorAction SilentlyContinue | 
                                            Select-Object -First 5
                                            foreach ($versionDir in $versionDirs) {
                                                $userGemBin = Join-Path $versionDir.FullName 'bin'
                                                if (Test-Path -LiteralPath $userGemBin -PathType Container) {
                                                    foreach ($ext in $extensions) {
                                                        $cmdPath = Join-Path $userGemBin "$normalizedName$ext"
                                                        if (Test-Path -LiteralPath $cmdPath) {
                                                            $result = $true
                                                            break
                                                        }
                                                    }
                                                    if ($result) { break }
                                                }
                                            }
                                            if ($result) { break }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if ($result) { break }
                }
            }
        }
    }

    # Cache the result (if caching enabled)
    if ($CacheTTLMinutes -gt 0) {
        $expires = $now.AddMinutes([double]$CacheTTLMinutes)
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $result
            Expires = $expires
        }
    }

    return $result
}

<#
.SYNOPSIS
    Clears the cached results used by Test-CachedCommand.
.DESCRIPTION
    Empties the in-memory cache so that subsequent Test-CachedCommand invocations
    recalculate command availability.
.OUTPUTS
    System.Boolean
#>
function global:Clear-TestCachedCommandCache {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not $global:TestCachedCommandCache) {
        return $false
    }

    $global:TestCachedCommandCache.Clear()
    return $true
}

<#
.SYNOPSIS
    Removes a single entry from the Test-CachedCommand cache.
.DESCRIPTION
    Deletes the cached availability result for the specified command name,
    forcing the next lookup to probe providers again.
.PARAMETER Name
    The command name whose cached result should be removed.
.OUTPUTS
    System.Boolean
#>
function global:Remove-TestCachedCommandCacheEntry {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not $global:TestCachedCommandCache -or [string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    $cacheKey = $Name.ToLowerInvariant()
    $removedEntry = $null
    return $global:TestCachedCommandCache.TryRemove($cacheKey, [ref]$removedEntry)
}

