# ===============================================
# Environment variable management functions
# Cross-platform persistent and session env var operations
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

function script:Test-RunningOnWindows {
    if (Get-Command Test-IsWindows -ErrorAction SilentlyContinue) {
        return Test-IsWindows
    }

    return ($PSVersionTable.Platform -eq 'Win32NT') -or ($IsWindows -eq $true)
}

function script:Get-EnvironmentVariableScope {
    param(
        [switch]$Global
    )

    if ($Global) {
        return [System.EnvironmentVariableTarget]::Machine
    }

    return [System.EnvironmentVariableTarget]::User
}

function script:Split-PathEnvironmentValue {
    param(
        [string]$PathValue
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return @()
    }

    if ($PathValue.Contains(';')) {
        return ($PathValue -split ';' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    if ($PathValue -match '^[A-Za-z]:\\') {
        return @($PathValue.Trim())
    }

    $pathSeparator = [System.IO.Path]::PathSeparator
    if ($PathValue.Contains($pathSeparator)) {
        return ($PathValue -split [regex]::Escape($pathSeparator) | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return @($PathValue.Trim())
}

function script:Join-PathEnvironmentValue {
    param(
        [string[]]$PathEntries
    )

    $pathSeparator = [System.IO.Path]::PathSeparator
    return ($PathEntries | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_.Trim()) }) -join $pathSeparator
}

<#
.SYNOPSIS
    Gets an environment variable value.
.DESCRIPTION
    Retrieves a persisted user or machine environment variable using the .NET API.
    Falls back to the current process environment when no persisted value exists.
.PARAMETER Name
    The name of the environment variable to retrieve.
    Type: [string]. Should be a valid environment variable name.
.PARAMETER Global
    If specified, retrieves the machine-wide value; otherwise, the user value.
.OUTPUTS
    String. The environment variable value, or null if not found.
.EXAMPLE
    Get-EnvVar

#>
function Get-EnvVar {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [switch]$Global
    )

    $scope = Get-EnvironmentVariableScope -Global:$Global

    if (Test-RunningOnWindows) {
        try {
            $persistedValue = [System.Environment]::GetEnvironmentVariable($Name, $scope)
            if ($null -ne $persistedValue) {
                return $persistedValue
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Verbose "Access denied reading environment variable '$Name' from $scope scope. Run with elevated permissions for machine-wide variables."
        }
        catch [System.Security.SecurityException] {
            Write-Verbose "Security exception reading environment variable '$Name' from $scope scope: $($_.Exception.Message)"
        }
        catch {
            Write-Verbose "Failed to read environment variable '$Name' from $scope scope: $($_.Exception.Message)"
        }
    }
    elseif ($Global) {
        Write-Verbose "Machine-wide environment variables are not supported on this platform."
        return $null
    }

    $processValue = [System.Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::Process)
    if ($null -ne $processValue) {
        return $processValue
    }

    $envItem = Get-Item -Path "env:$Name" -ErrorAction SilentlyContinue
    if ($null -ne $envItem) {
        return $envItem.Value
    }

    return $null
}

<#
.SYNOPSIS
    Sets an environment variable value.
.DESCRIPTION
    Sets a persisted user or machine environment variable using the .NET API and
    updates the current process environment. On Windows, broadcasts the change.
.PARAMETER Name
    The name of the environment variable.
    Type: [string]. Should be a valid environment variable name.
.PARAMETER Value
    The value to set. If null or empty, the variable is removed.
    Type: [string]. Can be null or empty to remove the variable.
.PARAMETER Global
    If specified, sets the machine-wide value; otherwise, the user value.
.OUTPUTS
    None. This function does not return a value.
.EXAMPLE
    Set-EnvVar

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

    $scope = Get-EnvironmentVariableScope -Global:$Global
    $shouldRemove = $null -eq $Value -or $Value -eq ''

    try {
        if (Test-RunningOnWindows) {
            if ($shouldRemove) {
                [System.Environment]::SetEnvironmentVariable($Name, $null, $scope)
                Remove-Item -Path "env:$Name" -Force -ErrorAction SilentlyContinue
            }
            else {
                [System.Environment]::SetEnvironmentVariable($Name, $Value, $scope)
                Set-Item -Path "env:$Name" -Value $Value -Force
            }

            Publish-EnvVar
        }
        else {
            if ($Global) {
                Write-Warning "Set-EnvVar -Global is not supported on this platform. Updating the current session only."
            }

            if ($shouldRemove) {
                [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::Process)
                Remove-Item -Path "env:$Name" -Force -ErrorAction SilentlyContinue
            }
            else {
                [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Process)
                Set-Item -Path "env:$Name" -Value $Value -Force
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'utilities.env.set' -Context @{
                env_var_name = $Name
                error_type   = 'UnauthorizedAccessException'
            }
        }
        else {
            Write-Error "Access denied setting environment variable '$Name'. Run with elevated permissions for machine-wide variables."
        }
        throw
    }
    catch [System.Security.SecurityException] {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'utilities.env.set' -Context @{
                env_var_name = $Name
                error_type   = 'SecurityException'
            }
        }
        else {
            Write-Error "Security exception setting environment variable '$Name': $($_.Exception.Message)"
        }
        throw
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'utilities.env.set' -Context @{
                env_var_name = $Name
            }
        }
        else {
            Write-Error "Failed to set environment variable '$Name': $($_.Exception.Message)"
        }
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
    if (-not (Test-RunningOnWindows)) {
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
.EXAMPLE
    Remove-Path

#>
function Remove-Path {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [switch]$Global
    )

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

    $pathArray = Split-PathEnvironmentValue -PathValue $currentPath | Where-Object { $_.Trim() -ne $Path.Trim() }
    $newPath = Join-PathEnvironmentValue -PathEntries $pathArray

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
.EXAMPLE
    Add-Path

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

    $currentPath = if ($Global) {
        Get-EnvVar -Name 'PATH' -Global
    }
    else {
        $env:PATH
    }

    if (-not $currentPath) {
        $newPath = $Path
    }
    else {
        $pathArray = Split-PathEnvironmentValue -PathValue $currentPath

        $normalizedPath = $Path.Trim()
        if ($pathArray -contains $normalizedPath) {
            Write-Verbose "Path '$normalizedPath' is already in PATH"
            return
        }

        $pathArray = @($normalizedPath) + $pathArray
        $newPath = Join-PathEnvironmentValue -PathEntries $pathArray
    }

    if ($Global) {
        Set-EnvVar -Name 'PATH' -Value $newPath -Global
    }
    else {
        $env:PATH = $newPath
    }
}
