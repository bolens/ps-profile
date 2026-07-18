<#
scripts/lib/core/PlatformPaths.psm1

.SYNOPSIS
    Cross-platform directory resolution from environment variables.

.DESCRIPTION
    Resolves temp, config, cache, and data directories using platform-appropriate
    environment variables and fallbacks (XDG on Unix, APPDATA/LOCALAPPDATA on Windows).
#>

function Test-PlatformPathsTestEnvFlag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $false
    }

    $normalized = $value.Trim().ToLowerInvariant()
    return $normalized -eq '1' -or $normalized -eq 'true'
}

function Resolve-UserHomeDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (Test-PlatformPathsTestEnvFlag -Name 'PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME') {
        return $null
    }

    $forcedHome = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME')
    if (-not [string]::IsNullOrWhiteSpace($forcedHome)) {
        return $forcedHome
    }

    if ($env:HOME) {
        return $env:HOME
    }

    if ($env:USERPROFILE) {
        return $env:USERPROFILE
    }

    try {
        return [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    Gets the system temp directory path.

.DESCRIPTION
    Checks TEMP, TMPDIR, and the .NET temp path fallback.

.OUTPUTS
    System.String

.EXAMPLE
    Get-TempDirectory
#>
function Get-TempDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($env:TEMP) {
        return $env:TEMP
    }

    if ($env:TMPDIR) {
        return $env:TMPDIR
    }

    return [System.IO.Path]::GetTempPath()
}

<#
.SYNOPSIS
    Gets the user config directory path.

.DESCRIPTION
    Honors XDG_CONFIG_HOME, APPDATA, and ~/.config fallbacks.

.OUTPUTS
    System.String

.EXAMPLE
    Get-ConfigDirectory
#>
function Get-ConfigDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($env:XDG_CONFIG_HOME) {
        return $env:XDG_CONFIG_HOME
    }

    if ($env:APPDATA) {
        return $env:APPDATA
    }

    $userHome = Resolve-UserHomeDirectory
    if ($userHome) {
        return Join-Path $userHome '.config'
    }

    return $null
}

<#
.SYNOPSIS
    Gets the application cache directory path.

.DESCRIPTION
    Honors PS_PROFILE_CACHE_DIR, then Windows LOCALAPPDATA, XDG_CACHE_HOME, and
    ~/.cache/<ApplicationName> fallbacks.

.PARAMETER ApplicationName
    Subdirectory name under the platform cache root.

.OUTPUTS
    System.String

.EXAMPLE
    Get-CacheDirectory -ApplicationName 'powershell-profile'
#>
function Get-CacheDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$ApplicationName = 'powershell-profile'
    )

    if ($env:PS_PROFILE_CACHE_DIR) {
        return $env:PS_PROFILE_CACHE_DIR
    }

    if ($env:LOCALAPPDATA) {
        return Join-Path $env:LOCALAPPDATA $ApplicationName
    }

    if ($env:XDG_CACHE_HOME) {
        return Join-Path $env:XDG_CACHE_HOME $ApplicationName
    }

    $userHome = Resolve-UserHomeDirectory
    if ($userHome) {
        return Join-Path $userHome '.cache' $ApplicationName
    }

    return Join-Path ([System.IO.Path]::GetTempPath()) $ApplicationName
}

<#
.SYNOPSIS
    Gets the user data directory path.

.DESCRIPTION
    Resolves XDG_DATA_HOME, LOCALAPPDATA, or ~/.local/share and optionally appends
    an application-specific subdirectory.

.PARAMETER ApplicationName
    Optional subdirectory under the platform data root.

.OUTPUTS
    System.String

.EXAMPLE
    Get-DataDirectory -ApplicationName 'powershell-profile'
#>
function Get-DataDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$ApplicationName
    )

    $dataRoot = $null

    if ($env:XDG_DATA_HOME) {
        $dataRoot = $env:XDG_DATA_HOME
    }
    elseif ($env:LOCALAPPDATA) {
        $dataRoot = $env:LOCALAPPDATA
    }
    else {
        $userHome = Resolve-UserHomeDirectory
        if ($userHome) {
            $dataRoot = Join-Path $userHome '.local' 'share'
        }
    }

    if (-not $dataRoot) {
        return $null
    }

    if ($ApplicationName) {
        return Join-Path $dataRoot $ApplicationName
    }

    return $dataRoot
}

<#
.SYNOPSIS
    Expands $HOME placeholders in a configured directory path.

.DESCRIPTION
    Replaces literal $HOME tokens using Resolve-UserHomeDirectory. Returns the
    original path when no user home can be resolved.

.PARAMETER PathValue
    Path string that may contain $HOME.

.OUTPUTS
    System.String

.EXAMPLE
    Expand-UserDirectoryPath -PathValue '$HOME/Downloads'
#>
function Expand-UserDirectoryPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$PathValue
    )

    $userHome = Resolve-UserHomeDirectory
    if (-not $userHome) {
        return $PathValue
    }

    $expanded = $PathValue.Replace('$HOME', $userHome)

    # user-dirs.dirs uses Unix separators; normalize to the host Join-Path layout.
    if ($expanded.StartsWith($userHome, [System.StringComparison]::OrdinalIgnoreCase)) {
        $remainder = $expanded.Substring($userHome.Length).TrimStart([char[]]@('/', '\'))
        if ([string]::IsNullOrWhiteSpace($remainder)) {
            return $userHome
        }

        $result = $userHome
        foreach ($segment in ($remainder -split '[\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            $result = Join-Path $result $segment
        }
        return $result
    }

    return $expanded
}

<#
.SYNOPSIS
    Reads an XDG user directory path from user-dirs.dirs.


.DESCRIPTION
    Reads an XDG user directory path from user-dirs.dirs.

.PARAMETER VariableName
    Variable to resolve, such as XDG_DOWNLOAD_DIR.


    .PARAMETER VariableName
    Variable to resolve, such as XDG_DOWNLOAD_DIR.

.OUTPUTS
    System.String


    .OUTPUTS
    System.String

.EXAMPLE

    .EXAMPLE
    Get-XdgUserDirectoryFromConfig -VariableName 'XDG_DOWNLOAD_DIR'
#>
function Get-XdgUserDirectoryFromConfig {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$VariableName
    )

    $configFile = if (Get-Command Get-ConfigDirectory -ErrorAction SilentlyContinue) {
        Join-Path (Get-ConfigDirectory) 'user-dirs.dirs'
    }
    else {
        $userHome = Resolve-UserHomeDirectory
        if ($userHome) {
            Join-Path $userHome '.config' 'user-dirs.dirs'
        }
    }

    if (-not ($configFile -and (Test-Path -LiteralPath $configFile))) {
        return $null
    }

    $pattern = "^\s*$([regex]::Escape($VariableName))\s*=\s*""(.+)""\s*$"
    foreach ($line in (Get-Content -LiteralPath $configFile -ErrorAction SilentlyContinue)) {
        if ($line -match '^\s*#') {
            continue
        }

        if ($line -match $pattern) {
            return Expand-UserDirectoryPath -PathValue $matches[1]
        }
    }

    return $null
}

<#
.SYNOPSIS
    Gets a well-known user directory path (Desktop, Downloads, Documents).

.DESCRIPTION
    Checks XDG environment variables, user-dirs.dirs, xdg-user-dir, Windows special
    folders, and finally ~/Name fallbacks.

.PARAMETER Name
    The directory name to resolve.

.OUTPUTS
    System.String

.EXAMPLE
    Get-UserDirectory -Name 'Downloads'
#>
function Get-UserDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Desktop', 'Downloads', 'Documents')]
        [string]$Name
    )

    $xdgEnvironmentVariable = switch ($Name) {
        'Desktop' { 'XDG_DESKTOP_DIR' }
        'Downloads' { 'XDG_DOWNLOAD_DIR' }
        'Documents' { 'XDG_DOCUMENTS_DIR' }
    }

    $xdgEnvItem = Get-Item -Path "env:$xdgEnvironmentVariable" -ErrorAction SilentlyContinue
    if ($null -ne $xdgEnvItem -and -not [string]::IsNullOrWhiteSpace($xdgEnvItem.Value)) {
        return Expand-UserDirectoryPath -PathValue $xdgEnvItem.Value
    }

    $configuredPath = Get-XdgUserDirectoryFromConfig -VariableName $xdgEnvironmentVariable
    if ($configuredPath) {
        return $configuredPath
    }

    $forcedHome = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME')
    if ([string]::IsNullOrWhiteSpace($forcedHome) -and (Get-Command xdg-user-dir -ErrorAction SilentlyContinue)) {
        $xdgName = switch ($Name) {
            'Desktop' { 'DESKTOP' }
            'Downloads' { 'DOWNLOAD' }
            'Documents' { 'DOCUMENTS' }
        }

        try {
            $xdgPath = & xdg-user-dir $xdgName 2>$null
            if ($LASTEXITCODE -eq 0 -and $xdgPath -and -not [string]::IsNullOrWhiteSpace($xdgPath)) {
                return $xdgPath.Trim()
            }
        }
        catch {
        }
    }

    try {
        $specialFolder = switch ($Name) {
            'Desktop' { [System.Environment+SpecialFolder]::Desktop }
            'Documents' { [System.Environment+SpecialFolder]::MyDocuments }
            default { $null }
        }

        # When tests (or hosts) force a user home, skip OS special folders so
        # ~/Name fallbacks remain deterministic across Windows and Unix.
        if ($null -ne $specialFolder -and [string]::IsNullOrWhiteSpace($forcedHome)) {
            $specialPath = [System.Environment]::GetFolderPath($specialFolder)
            if ($specialPath -and -not [string]::IsNullOrWhiteSpace($specialPath)) {
                return $specialPath
            }
        }
    }
    catch {
    }

    $userHome = Resolve-UserHomeDirectory
    if ($userHome) {
        return Join-Path $userHome $Name
    }

    return $null
}

<#
.SYNOPSIS
    Gets Wrangler config directory and file paths.
.OUTPUTS
.DESCRIPTION
    Gets Wrangler config directory and file paths.
    .OUTPUTS
    System.Collections.Hashtable with Dir and File keys.
#>
function Get-WranglerConfigPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $configBase = Get-ConfigDirectory
    if (-not $configBase) {
        throw 'Unable to determine config directory. Set XDG_CONFIG_HOME, APPDATA, or HOME.'
    }

    $useWindowsAppDataLayout = $env:APPDATA -and ($configBase -eq $env:APPDATA)
    $dir = if ($useWindowsAppDataLayout) {
        Join-Path $configBase 'xdg.config' '.wrangler' 'config'
    }
    else {
        Join-Path $configBase '.wrangler' 'config'
    }

    return @{
        Dir  = $dir
        File = Join-Path $dir 'default.toml'
    }
}

Export-ModuleMember -Function @(
    'Get-TempDirectory'
    'Get-ConfigDirectory'
    'Get-CacheDirectory'
    'Get-DataDirectory'
    'Get-UserDirectory'
    'Get-WranglerConfigPaths'
)
