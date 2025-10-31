# ===============================================
# 05-utilities.ps1
# Utility functions migrated from utilities.ps1
# ===============================================

# Reload profile in current session
<#
.SYNOPSIS
    Reloads the PowerShell profile.
.DESCRIPTION
    Dots-sources the current profile file to reload all functions and settings.
#>
function reload { .$PROFILE }
# Edit profile in code editor
<#
.SYNOPSIS
    Opens the profile in VS Code.
.DESCRIPTION
    Launches VS Code to edit the current PowerShell profile file.
#>
function edit-profile { code $PROFILE }
# Weather info for a location (city, zip, etc.)
<#
.SYNOPSIS
    Shows weather information.
.DESCRIPTION
    Retrieves and displays weather information for a specified location using wttr.in.
#>
function weather { Invoke-WebRequest -Uri "https://wttr.in/$args" }
# Get public IP address
<#
.SYNOPSIS
    Shows public IP address.
.DESCRIPTION
    Retrieves and displays the current public IP address.
#>
function myip { (Invoke-RestMethod ifconfig.me).Trim() }
# Run speedtest-cli
<#
.SYNOPSIS
    Runs internet speed test.
.DESCRIPTION
    Executes speedtest-cli to measure internet connection speed.
#>
function speedtest { speedtest-cli }
# History helpers
<#
.SYNOPSIS
    Shows recent command history.
.DESCRIPTION
    Displays the last 20 commands from the PowerShell command history.
#>
function Get-History { Get-History | Select-Object -Last 20 }
# Search history
<#
.SYNOPSIS
    Searches command history.
.DESCRIPTION
    Searches through PowerShell command history for the specified pattern.
#>
function hg { Get-History | Select-String $args }
# Generate random password
<#
.SYNOPSIS
    Generates a random password.
.DESCRIPTION
    Creates a 16-character random password using alphanumeric characters.
#>
function pwgen { -join ((1..16) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) }) }
# URL encode
<#
.SYNOPSIS
    URL-encodes a string.
.DESCRIPTION
    Encodes a string for use in URLs.
#>
function url-encode { param([string]$text) [uri]::EscapeDataString($text) }
# URL decode
<#
.SYNOPSIS
    URL-decodes a string.
.DESCRIPTION
    Decodes a URL-encoded string.
#>
function url-decode { param([string]$text) [uri]::UnescapeDataString($text) }
# Convert Unix timestamp to DateTime
<#
.SYNOPSIS
    Converts Unix timestamp to DateTime.
.DESCRIPTION
    Converts a Unix timestamp (seconds since epoch) to a local DateTime.
#>
function from-epoch { param([long]$epoch) [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime() }
# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Converts DateTime to Unix timestamp.
.DESCRIPTION
    Converts a DateTime object or string to a Unix timestamp (seconds since epoch).
#>
function to-epoch { param([DateTime]$date = (Get-Date)) [DateTimeOffset]::new($date).ToUnixTimeSeconds() }
# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Gets current Unix timestamp.
.DESCRIPTION
    Returns the current date and time as a Unix timestamp (seconds since epoch).
#>
function epoch { [DateTimeOffset]::Now.ToUnixTimeSeconds() }
# Get current date and time in standard format
<#
.SYNOPSIS
    Shows current date and time.
.DESCRIPTION
    Displays the current date and time in a standard format.
#>
function now { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
# Open current directory in File Explorer
<#
.SYNOPSIS
    Opens current directory in File Explorer.
.DESCRIPTION
    Launches Windows File Explorer in the current directory.
#>
function open-explorer { explorer.exe . }
# List all user-defined functions in current session
<#
.SYNOPSIS
    Lists user-defined functions.
.DESCRIPTION
    Displays all user-defined functions in the current PowerShell session.
#>
function list-functions { Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name, Definition | Format-Table -AutoSize }
# Backup current profile to timestamped .bak file
<#
.SYNOPSIS
    Creates a backup of the profile.
.DESCRIPTION
    Creates a timestamped backup copy of the current PowerShell profile.
#>
function backup-profile { Copy-Item $PROFILE ($PROFILE + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak') }

# Environment variable management functions (for Scoop compatibility)
<#
.SYNOPSIS
    Gets an environment variable value from the registry.
.DESCRIPTION
    Retrieves the value of an environment variable from the Windows registry.
.PARAMETER Name
    The name of the environment variable.
.PARAMETER Global
    If specified, gets the variable from the system-wide registry; otherwise, from user registry.
#>
function Get-EnvVar {
    param(
        [string]$Name,
        [switch]$Global
    )

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
.PARAMETER Value
    The value to set. If null or empty, the variable is removed.
.PARAMETER Global
    If specified, sets the variable in the system-wide registry; otherwise, in user registry.
#>
function Set-EnvVar {
    param(
        [string]$Name,
        [string]$Value,
        [switch]$Global
    )

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
        [string]$Path,
        [switch]$Global
    )

    if (-not $Path) {
        Write-Warning "No path specified to remove"
        return
    }

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
    $pathArray = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() -ne $Path.Trim() }

    # Join back into PATH string
    $newPath = $pathArray -join ';'

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
        [string]$Path,
        [switch]$Global
    )

    if (-not $Path) {
        Write-Warning "No path specified to add"
        return
    }

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
        # Split PATH into array
        $pathArray = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() }

        # Check if path already exists
        $normalizedPath = $Path.Trim()
        if ($pathArray -contains $normalizedPath) {
            Write-Verbose "Path '$normalizedPath' is already in PATH"
            return
        }

        # Add the new path
        $pathArray = @($normalizedPath) + $pathArray
        $newPath = $pathArray -join ';'
    }

    # Update PATH
    if ($Global) {
        Set-EnvVar -Name 'PATH' -Value $newPath -Global
    }
    else {
        $env:PATH = $newPath
    }
}
