<#
scripts/lib/Platform.psm1

.SYNOPSIS
    Platform detection utilities.

.DESCRIPTION
    Provides functions for detecting the current operating system platform
    (Windows, Linux, macOS) for cross-platform script compatibility.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

function Test-PlatformTestEnvFlag {
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

function Get-PlatformForcedName {
    $forcedName = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_NAME')
    if ([string]::IsNullOrWhiteSpace($forcedName)) {
        return $null
    }

    return $forcedName.Trim()
}

<#
.SYNOPSIS
    Detects the current operating system platform.

.DESCRIPTION
    Returns the current operating system platform (Windows, Linux, macOS).
    Useful for cross-platform script compatibility.

.OUTPUTS
    String: "Windows", "Linux", or "macOS"

.EXAMPLE
    $platform = Get-Platform
    if ($platform -eq "Windows") {
        # Windows-specific code
    }
#>
function Get-Platform {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $platformName = 'Unknown'
    $detectedWindows = $false
    $detectedLinux = $false
    $detectedMac = $false

    $forcedName = Get-PlatformForcedName
    if ($forcedName) {
        $platformName = $forcedName
        $detectedWindows = $forcedName -eq 'Windows'
        $detectedLinux = $forcedName -eq 'Linux'
        $detectedMac = $forcedName -eq 'macOS'
    }
    elseif (Test-PlatformTestEnvFlag -Name 'PS_PROFILE_PLATFORM_FORCE_NATURAL_WINDOWS') {
        $platformName = 'Windows'
        $detectedWindows = $true
    }
    elseif (Test-PlatformTestEnvFlag -Name 'PS_PROFILE_PLATFORM_FORCE_NATURAL_MACOS') {
        $platformName = 'macOS'
        $detectedMac = $true
    }
    elseif (Test-PlatformTestEnvFlag -Name 'PS_PROFILE_PLATFORM_FORCE_NATURAL_FALLBACK') {
        $forcedOs = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM')
        $os = if ($forcedOs -eq 'Win32NT') {
            [System.PlatformID]::Win32NT
        }
        elseif ($forcedOs -eq 'Unix') {
            [System.PlatformID]::Unix
        }
        else {
            [System.Environment]::OSVersion.Platform
        }

        if ($os -eq [System.PlatformID]::Win32NT) {
            $platformName = 'Windows'
            $detectedWindows = $true
        }
        elseif ($os -eq [System.PlatformID]::Unix) {
            $forcedUname = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_UNAME')
            $uname = if (-not [string]::IsNullOrWhiteSpace($forcedUname)) {
                $forcedUname.Trim()
            }
            elseif (Get-Command uname -ErrorAction SilentlyContinue) {
                & uname
            }
            else {
                $null
            }

            if ($uname -eq 'Darwin') {
                $platformName = 'macOS'
                $detectedMac = $true
            }
            else {
                $platformName = 'Linux'
                $detectedLinux = $true
            }
        }
    }
    elseif (Test-PlatformTestEnvFlag -Name 'PS_PROFILE_PLATFORM_FORCE_FALLBACK') {
        $forcedOs = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM')
        $os = if ($forcedOs -eq 'Win32NT') {
            [System.PlatformID]::Win32NT
        }
        elseif ($forcedOs -eq 'Unix') {
            [System.PlatformID]::Unix
        }
        else {
            [System.Environment]::OSVersion.Platform
        }

        if ($os -eq [System.PlatformID]::Win32NT) {
            $platformName = 'Windows'
            $detectedWindows = $true
        }
        elseif ($os -eq [System.PlatformID]::Unix) {
            $forcedUname = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_UNAME')
            $uname = if (-not [string]::IsNullOrWhiteSpace($forcedUname)) {
                $forcedUname.Trim()
            }
            elseif (Get-Command uname -ErrorAction SilentlyContinue) {
                & uname
            }
            else {
                $null
            }

            if ($uname -eq 'Darwin') {
                $platformName = 'macOS'
                $detectedMac = $true
            }
            else {
                $platformName = 'Linux'
                $detectedLinux = $true
            }
        }
    }
    elseif (Test-PlatformTestEnvFlag -Name 'PS_PROFILE_PLATFORM_FORCE_FINAL_ELSE') {
        $forcedOs = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM')
        $os = if ($forcedOs -eq 'Win32NT') {
            [System.PlatformID]::Win32NT
        }
        elseif ($forcedOs -eq 'Unix') {
            [System.PlatformID]::Unix
        }
        else {
            [System.Environment]::OSVersion.Platform
        }

        if ($os -eq [System.PlatformID]::Win32NT) {
            $platformName = 'Windows'
            $detectedWindows = $true
        }
        elseif ($os -eq [System.PlatformID]::Unix) {
            $forcedUname = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_UNAME')
            $uname = if (-not [string]::IsNullOrWhiteSpace($forcedUname)) {
                $forcedUname.Trim()
            }
            elseif (Get-Command uname -ErrorAction SilentlyContinue) {
                & uname
            }
            else {
                $null
            }

            if ($uname -eq 'Darwin') {
                $platformName = 'macOS'
                $detectedMac = $true
            }
            else {
                $platformName = 'Linux'
                $detectedLinux = $true
            }
        }
    }
    elseif (Test-PlatformTestEnvFlag -Name 'PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE') {
        $forcedOs = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM')
        $os = if ($forcedOs -eq 'Win32NT') {
            [System.PlatformID]::Win32NT
        }
        elseif ($forcedOs -eq 'Unix') {
            [System.PlatformID]::Unix
        }
        else {
            [System.Environment]::OSVersion.Platform
        }

        if ($os -eq [System.PlatformID]::Win32NT) {
            $platformName = 'Windows'
            $detectedWindows = $true
        }
        elseif ($os -eq [System.PlatformID]::Unix) {
            $forcedUname = [Environment]::GetEnvironmentVariable('PS_PROFILE_PLATFORM_FORCE_UNAME')
            $uname = if (-not [string]::IsNullOrWhiteSpace($forcedUname)) {
                $forcedUname.Trim()
            }
            elseif (Get-Command uname -ErrorAction SilentlyContinue) {
                & uname
            }
            else {
                $null
            }

            if ($uname -eq 'Darwin') {
                $platformName = 'macOS'
                $detectedMac = $true
            }
            else {
                $platformName = 'Linux'
                $detectedLinux = $true
            }
        }
    }
    elseif ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        $platformName = 'Windows'
        $detectedWindows = $true
    }
    elseif ($IsLinux) {
        $platformName = 'Linux'
        $detectedLinux = $true
    }
    elseif ($IsMacOS) {
        $platformName = 'macOS'
        $detectedMac = $true
    }
    else {
        # Fallback detection using .NET and uname for edge cases
        $os = [System.Environment]::OSVersion.Platform
        if ($os -eq [System.PlatformID]::Win32NT) {
            $platformName = 'Windows'
            $detectedWindows = $true
        }
        elseif ($os -eq [System.PlatformID]::Unix) {
            $uname = if (Get-Command uname -ErrorAction SilentlyContinue) { & uname } else { $null }
            if ($uname -eq 'Darwin') {
                $platformName = 'macOS'
                $detectedMac = $true
            }
            else {
                $platformName = 'Linux'
                $detectedLinux = $true
            }
        }
    }

    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    $description = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription

    return [PSCustomObject]@{
        Name         = $platformName
        IsWindows    = $detectedWindows
        IsLinux      = $detectedLinux
        IsMacOS      = $detectedMac
        Architecture = $architecture
        Description  = $description
    }
}

<#
.SYNOPSIS
    Checks if the current platform is Windows.

.DESCRIPTION
    Returns true if running on Windows, false otherwise.

.OUTPUTS
    Boolean

.EXAMPLE
    if (Test-IsWindows) {
        # Windows-specific code
    }
#>
function Test-IsWindows {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return (Get-Platform).IsWindows
}

<#
.SYNOPSIS
    Checks if the current platform is Linux.

.DESCRIPTION
    Returns true if running on Linux, false otherwise.

.OUTPUTS
    Boolean

.EXAMPLE
    if (Test-IsLinux) {
        # Linux-specific code
    }
#>
function Test-IsLinux {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return (Get-Platform).IsLinux
}

<#
.SYNOPSIS
    Checks if the current platform is macOS.

.DESCRIPTION
    Returns true if running on macOS, false otherwise.

.OUTPUTS
    Boolean

.EXAMPLE
    if (Test-IsMacOS) {
        # macOS-specific code
    }
#>
function Test-IsMacOS {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return (Get-Platform).IsMacOS
}

# Export functions
Export-ModuleMember -Function @(
    'Get-Platform',
    'Test-IsWindows',
    'Test-IsLinux',
    'Test-IsMacOS'
)

