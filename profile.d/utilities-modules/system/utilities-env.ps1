# ===============================================
# Environment variable management functions
# Registry-based environment variable operations (Windows)
# ===============================================

# Import Platform module for Test-IsWindows
$platformModulePath = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) 'scripts' 'lib' 'core' 'Platform.psm1'
if ($platformModulePath -and -not [string]::IsNullOrWhiteSpace($platformModulePath) -and (Test-Path -LiteralPath $platformModulePath)) {
    try {
        Import-Module $platformModulePath -DisableNameChecking -ErrorAction Stop
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to import Platform module: $($_.Exception.Message)"
        }
    }
}

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
    # Use fallback if Test-IsWindows is not available
    $isWindows = if (Get-Command Test-IsWindows -ErrorAction SilentlyContinue) {
        Test-IsWindows
    }
    else {
        $PSVersionTable.Platform -eq 'Win32NT' -or $IsWindows
    }
    
    if (-not $isWindows) {
        Write-Warning "Get-EnvVar requires Windows. Use `$env:$Name on other platforms."
        # Return current session value as fallback
        return (Get-Item -Path "env:$Name" -ErrorAction SilentlyContinue).Value
    }

    try {
        $registerKey = if ($Global) {
            Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        }
        else {
            Get-Item -Path 'HKCU:'
        }
        $envRegisterKey = $registerKey.OpenSubKey('Environment')
        if ($null -eq $envRegisterKey) {
            # Registry key doesn't exist, return null
            return $null
        }
        $registryValueOption = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        return $envRegisterKey.GetValue($Name, $null, $registryValueOption)
    }
    catch [System.UnauthorizedAccessException] {
        Write-Verbose "Access denied accessing registry for Get-EnvVar '$Name'. Run with elevated permissions for system-wide variables."
        return $null
    }
    catch [System.Security.SecurityException] {
        Write-Verbose "Security exception accessing registry for Get-EnvVar '$Name': $($_.Exception.Message)"
        return $null
    }
    catch {
        # Handle other registry access errors gracefully
        Write-Verbose "Failed to access registry for Get-EnvVar '$Name': $($_.Exception.Message)"
        return $null
    }
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
    # Use fallback if Test-IsWindows is not available
    $isWindows = if (Get-Command Test-IsWindows -ErrorAction SilentlyContinue) {
        Test-IsWindows
    }
    else {
        $PSVersionTable.Platform -eq 'Win32NT' -or $IsWindows
    }
    
    if (-not $isWindows) {
        Write-Warning "Set-EnvVar requires Windows. Use `$env:$Name = '$Value' on other platforms."
        # Set session value as fallback
        Set-Item -Path "env:$Name" -Value $Value -ErrorAction SilentlyContinue
        return
    }

    try {
        $registerKey = if ($Global) {
            Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        }
        else {
            Get-Item -Path 'HKCU:'
        }
        $envRegisterKey = $registerKey.OpenSubKey('Environment', $true)
        if ($null -eq $envRegisterKey) {
            Write-Warning "Failed to open Environment registry key"
            return
        }
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
    catch [System.UnauthorizedAccessException] {
        Write-Error "Access denied setting environment variable '$Name'. Run with elevated permissions for system-wide variables."
        throw
    }
    catch [System.Security.SecurityException] {
        Write-Error "Security exception setting environment variable '$Name': $($_.Exception.Message)"
        throw
    }
    catch {
        Write-Error "Failed to set environment variable '$Name': $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Broadcasts environment variable changes to all windows.
.DESCRIPTION
    Sends a WM_SETTINGCHANGE message to notify all windows of environment variable changes.
#>
function Publish-EnvVar {
    # Windows-only function for broadcasting environment variable changes
    # Use fallback if Test-IsWindows is not available
    $isWindows = if (Get-Command Test-IsWindows -ErrorAction SilentlyContinue) {
        Test-IsWindows
    }
    else {
        $PSVersionTable.Platform -eq 'Win32NT' -or $IsWindows
    }
    
    if (-not $isWindows) {
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
                if (-not ($_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container -ErrorAction SilentlyContinue))) {
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

