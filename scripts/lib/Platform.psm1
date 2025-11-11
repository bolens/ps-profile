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

    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
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

