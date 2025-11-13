# ===============================================
# 05-utilities.ps1
# Utility functions migrated from utilities.ps1
# ===============================================

# Security helper for path validation
<#
.SYNOPSIS
    Validates that a path is safe and within a base directory.
.DESCRIPTION
    Checks if a resolved path is within a specified base directory to prevent
    path traversal attacks. Useful for validating user input before file operations.
.PARAMETER Path
    The path to validate.
.PARAMETER BasePath
    The base directory that the path must be within.
.OUTPUTS
    System.Boolean. Returns $true if path is safe, $false otherwise.
.EXAMPLE
    if (Test-SafePath -Path $userPath -BasePath $homeDir) {
        # Safe to use the path
    }
#>
function Test-SafePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$BasePath
    )

    try {
        # Try to resolve the path if it exists
        try {
            $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop | Select-Object -ExpandProperty Path
        }
        catch {
            # If path doesn't exist, get the unresolved provider path and normalize it
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)
        }

        # Try to resolve the base path if it exists
        try {
            $resolvedBase = Resolve-Path -Path $BasePath -ErrorAction Stop | Select-Object -ExpandProperty Path
        }
        catch {
            # If base path doesn't exist, get the unresolved provider path and normalize it
            $resolvedBase = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BasePath)
            $resolvedBase = [System.IO.Path]::GetFullPath($resolvedBase)
        }

        # Ensure base path ends with directory separator for proper comparison
        if (-not $resolvedBase.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
            $resolvedBase += [System.IO.Path]::DirectorySeparatorChar
        }

        return $resolvedPath.StartsWith($resolvedBase, [System.StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        # If path resolution fails, consider it unsafe
        return $false
    }
}

# Reload profile in current session
<#
.SYNOPSIS
    Reloads the PowerShell profile.
.DESCRIPTION
    Dots-sources the current profile file to reload all functions and settings.
#>
function Reload-Profile { .$PROFILE }
Set-Alias -Name reload -Value Reload-Profile -ErrorAction SilentlyContinue

# Edit profile in code editor
<#
.SYNOPSIS
    Opens the profile in VS Code.
.DESCRIPTION
    Launches VS Code to edit the current PowerShell profile file.
#>
function Edit-Profile { code $PROFILE }
Set-Alias -Name edit-profile -Value Edit-Profile -ErrorAction SilentlyContinue

# Weather info for a location (city, zip, etc.)
<#
.SYNOPSIS
    Shows weather information.
.DESCRIPTION
    Retrieves and displays weather information for a specified location using wttr.in.
#>
function Get-Weather { Invoke-WebRequest -Uri "https://wttr.in/$args" }
Set-Alias -Name weather -Value Get-Weather -ErrorAction SilentlyContinue

# Get public IP address
<#
.SYNOPSIS
    Shows public IP address.
.DESCRIPTION
    Retrieves and displays the current public IP address.
#>
function Get-MyIP { (Invoke-RestMethod ifconfig.me).Trim() }
Set-Alias -Name myip -Value Get-MyIP -ErrorAction SilentlyContinue

# Run speedtest-cli
<#
.SYNOPSIS
    Runs internet speed test.
.DESCRIPTION
    Executes speedtest-cli to measure internet connection speed.
#>
function Start-SpeedTest { & (Get-Command speedtest.exe).Source --accept-license }
Set-Alias -Name speedtest -Value Start-SpeedTest -ErrorAction SilentlyContinue

# History helpers
<#
.SYNOPSIS
    Shows recent command history.
.DESCRIPTION
    Displays the last 20 commands from the PowerShell command history.
#>
function Get-History { Microsoft.PowerShell.Core\Get-History | Select-Object -Last 20 }

# Search history
<#
.SYNOPSIS
    Searches command history.
.DESCRIPTION
    Searches through PowerShell command history for the specified pattern.
#>
function Find-History { Microsoft.PowerShell.Core\Get-History | Select-String $args }
Set-Alias -Name hg -Value Find-History -ErrorAction SilentlyContinue

# Generate random password
<#
.SYNOPSIS
    Generates a random password.
.DESCRIPTION
    Creates a 16-character random password using alphanumeric characters.
#>
function New-RandomPassword { -join ((1..16) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) }) }
Set-Alias -Name pwgen -Value New-RandomPassword -ErrorAction SilentlyContinue

# URL encode
<#
.SYNOPSIS
    URL-encodes a string.
.DESCRIPTION
    Encodes a string for use in URLs.
#>
function ConvertTo-UrlEncoded { param([string]$text) [uri]::EscapeDataString($text) }
Set-Alias -Name url-encode -Value ConvertTo-UrlEncoded -ErrorAction SilentlyContinue

# URL decode
<#
.SYNOPSIS
    URL-decodes a string.
.DESCRIPTION
    Decodes a URL-encoded string.
#>
function ConvertFrom-UrlEncoded { param([string]$text) [uri]::UnescapeDataString($text) }
Set-Alias -Name url-decode -Value ConvertFrom-UrlEncoded -ErrorAction SilentlyContinue

# Convert Unix timestamp to DateTime
<#
.SYNOPSIS
    Converts Unix timestamp to DateTime.
.DESCRIPTION
    Converts a Unix timestamp (seconds since epoch) to a local DateTime.
#>
function ConvertFrom-Epoch { param([long]$epoch) [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime() }
Set-Alias -Name from-epoch -Value ConvertFrom-Epoch -ErrorAction SilentlyContinue

# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Converts DateTime to Unix timestamp.
.DESCRIPTION
    Converts a DateTime object or string to a Unix timestamp (seconds since epoch).
#>
function ConvertTo-Epoch { param([DateTime]$date = (Get-Date)) [DateTimeOffset]::new($date).ToUnixTimeSeconds() }
Set-Alias -Name to-epoch -Value ConvertTo-Epoch -ErrorAction SilentlyContinue

# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Gets current Unix timestamp.
.DESCRIPTION
    Returns the current date and time as a Unix timestamp (seconds since epoch).
#>
function Get-Epoch { [DateTimeOffset]::Now.ToUnixTimeSeconds() }
Set-Alias -Name epoch -Value Get-Epoch -ErrorAction SilentlyContinue

# Get current date and time in standard format
<#
.SYNOPSIS
    Shows current date and time.
.DESCRIPTION
    Displays the current date and time in a standard format.
#>
function Get-DateTime { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
Set-Alias -Name now -Value Get-DateTime -ErrorAction SilentlyContinue

# Open current directory in File Explorer
<#
.SYNOPSIS
    Opens current directory in File Explorer.
.DESCRIPTION
    Launches Windows File Explorer in the current directory.
#>
function Open-Explorer { explorer.exe . }
Set-Alias -Name open-explorer -Value Open-Explorer -ErrorAction SilentlyContinue

# List all user-defined functions in current session
<#
.SYNOPSIS
    Lists user-defined functions.
.DESCRIPTION
    Displays all user-defined functions in the current PowerShell session.
#>
function Get-Functions { @(Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name, Definition) }
Set-Alias -Name list-functions -Value Get-Functions -ErrorAction SilentlyContinue

# Backup current profile to timestamped .bak file
<#
.SYNOPSIS
    Creates a backup of the profile.
.DESCRIPTION
    Creates a timestamped backup copy of the current PowerShell profile.
#>
function Backup-Profile { Copy-Item $PROFILE ($PROFILE + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak') }
Set-Alias -Name backup-profile -Value Backup-Profile -ErrorAction SilentlyContinue

# Environment variable management functions (for Scoop compatibility)
<#
.SYNOPSIS
    Gets an environment variable value from the registry.
.DESCRIPTION
    Retrieves the value of an environment variable from the Windows registry.
    Works with both user and system-wide environment variables.
.PARAMETER Name
    The name of the environment variable to retrieve.
    Type: [string]. Should be a valid environment variable name.
.PARAMETER Global
    If specified, retrieves from system-wide registry; otherwise, from user registry.
.OUTPUTS
    String. The environment variable value, or null if not found.
#>
function Get-EnvVar {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [switch]$Global
    )

    # Registry operations only work on Windows
    if (-not (Test-IsWindows)) {
        Write-Warning "Get-EnvVar requires Windows. Use `$env:$Name on other platforms."
        # Return current session value as fallback
        return (Get-Item -Path "env:$Name" -ErrorAction SilentlyContinue).Value
    }

    $registerKey = if ($Global) {
        Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    }
    else {
        Get-Item -Path 'HKCU:'
    }
    $envRegisterKey = $registerKey.OpenSubKey('Environment')
    $registryValueOption = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    $envRegisterKey.GetValue($Name, $null, $registryValueOption)
}

<#
.SYNOPSIS
    Sets an environment variable value in the registry.
.DESCRIPTION
    Sets the value of an environment variable in the Windows registry and broadcasts the change.
.PARAMETER Name
    The name of the environment variable.
    Type: [string]. Should be a valid environment variable name.
.PARAMETER Value
    The value to set. If null or empty, the variable is removed.
    Type: [string]. Can be null or empty to remove the variable.
.PARAMETER Global
    If specified, sets the variable in the system-wide registry; otherwise, in user registry.
.OUTPUTS
    None. This function does not return a value.
#>
function Set-EnvVar {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Value,
        [switch]$Global
    )

    # Registry operations only work on Windows
    if (-not (Test-IsWindows)) {
        Write-Warning "Set-EnvVar requires Windows. Use `$env:$Name = '$Value' on other platforms."
        # Set session value as fallback
        Set-Item -Path "env:$Name" -Value $Value -ErrorAction SilentlyContinue
        return
    }

    $registerKey = if ($Global) {
        Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    }
    else {
        Get-Item -Path 'HKCU:'
    }
    $envRegisterKey = $registerKey.OpenSubKey('Environment', $true)
    if ($null -eq $Value -or $Value -eq '') {
        if ($envRegisterKey.GetValue($Name)) {
            $envRegisterKey.DeleteValue($Name)
        }
    }
    else {
        $registryValueKind = if ($Value.Contains('%')) {
            [Microsoft.Win32.RegistryValueKind]::ExpandString
        }
        elseif ($envRegisterKey.GetValue($Name)) {
            $envRegisterKey.GetValueKind($Name)
        }
        else {
            [Microsoft.Win32.RegistryValueKind]::String
        }
        $envRegisterKey.SetValue($Name, $Value, $registryValueKind)
    }
    Publish-EnvVar
}

<#
.SYNOPSIS
    Broadcasts environment variable changes to all windows.
.DESCRIPTION
    Sends a WM_SETTINGCHANGE message to notify all windows of environment variable changes.
#>
function Publish-EnvVar {
    # Windows-only function for broadcasting environment variable changes
    if (-not (Test-IsWindows)) {
        # On non-Windows platforms, environment variable changes are session-only
        return
    }

    if (-not ('Win32.NativeMethods' -as [Type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult
);
'@
    }

    $HWND_BROADCAST = [IntPtr] 0xffff
    $WM_SETTINGCHANGE = 0x1a
    $result = [UIntPtr]::Zero

    [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'Environment',
        2,
        5000,
        [ref] $result
    ) | Out-Null
}

<#
.SYNOPSIS
    Removes a directory from the PATH environment variable.
.DESCRIPTION
    Removes the specified directory from the PATH environment variable if it exists.
.PARAMETER Path
    The directory path to remove from PATH.
.PARAMETER Global
    If specified, modifies the system-wide PATH; otherwise, modifies user PATH.
#>
function Remove-Path {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [switch]$Global
    )

    # Get current PATH
    $currentPath = if ($Global) {
        Get-EnvVar -Name 'PATH' -Global
    }
    else {
        $env:PATH
    }

    if (-not $currentPath) {
        Write-Warning "PATH environment variable not found"
        return
    }

    # Split PATH into array and remove the specified path
    # Use platform-appropriate path separator
    $pathSeparator = [System.IO.Path]::PathSeparator
    $pathArray = $currentPath -split [regex]::Escape($pathSeparator) | Where-Object { $_ -and $_.Trim() -ne $Path.Trim() }

    # Join back into PATH string
    $newPath = $pathArray -join $pathSeparator

    # Update PATH
    if ($Global) {
        Set-EnvVar -Name 'PATH' -Value $newPath -Global
    }
    else {
        $env:PATH = $newPath
    }
}

<#
.SYNOPSIS
    Adds a directory to the PATH environment variable.
.DESCRIPTION
    Adds the specified directory to the PATH environment variable if it doesn't already exist.
.PARAMETER Path
    The directory path to add to PATH.
.PARAMETER Global
    If specified, modifies the system-wide PATH; otherwise, modifies user PATH.
#>
function Add-Path {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Container -ErrorAction SilentlyContinue)) {
                    throw "Path does not exist or is not a directory: $_"
                }
                $true
            })]
        [string]$Path,
        [switch]$Global
    )

    # Get current PATH
    $currentPath = if ($Global) {
        Get-EnvVar -Name 'PATH' -Global
    }
    else {
        $env:PATH
    }

    if (-not $currentPath) {
        # If PATH doesn't exist, create it with the new path
        $newPath = $Path
    }
    else {
        # Split PATH into array using platform-appropriate separator
        $pathSeparator = [System.IO.Path]::PathSeparator
        $pathArray = $currentPath -split [regex]::Escape($pathSeparator) | Where-Object { $_ -and $_.Trim() }

        # Check if path already exists
        $normalizedPath = $Path.Trim()
        if ($pathArray -contains $normalizedPath) {
            Write-Verbose "Path '$normalizedPath' is already in PATH"
            return
        }

        # Add the new path
        $pathArray = @($normalizedPath) + $pathArray
        $newPath = $pathArray -join $pathSeparator
    }

    # Update PATH
    if ($Global) {
        Set-EnvVar -Name 'PATH' -Value $newPath -Global
    }
    else {
        $env:PATH = $newPath
    }
}
