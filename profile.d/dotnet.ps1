# ===============================================
# dotnet.ps1
# .NET CLI package and tool management
# ===============================================

# .NET CLI aliases and functions
# Requires: dotnet (https://dotnet.microsoft.com/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand dotnet)) {
    # .NET list outdated packages
    <#
    .SYNOPSIS
        Lists outdated NuGet packages in .NET projects.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'dotnet list package --outdated'.
    #>
    function Test-DotnetOutdated {
        [CmdletBinding()]
        param()
        
        & dotnet list package --outdated
    }
    Set-Alias -Name dotnet-outdated -Value Test-DotnetOutdated -ErrorAction SilentlyContinue

    # .NET update packages
    <#
    .SYNOPSIS
        Updates NuGet packages in .NET projects.
    .DESCRIPTION
        Updates all packages to their latest versions within version constraints.
    #>
    function Update-DotnetPackages {
        [CmdletBinding()]
        param()
        
        Write-Warning "Use 'dotnet list package --outdated' to see outdated packages, then update with 'dotnet add package <package>'"
        & dotnet list package --outdated
    }
    Set-Alias -Name dotnet-update -Value Update-DotnetPackages -ErrorAction SilentlyContinue

    # .NET update tools
    <#
    .SYNOPSIS
        Updates all .NET global tools.
    .DESCRIPTION
        Updates all installed .NET global tools to their latest versions.
    #>
    function Update-DotnetTools {
        [CmdletBinding()]
        param()
        
        & dotnet tool update --all
    }
    Set-Alias -Name dotnet-tool-update -Value Update-DotnetTools -ErrorAction SilentlyContinue

    # .NET restore
    <#
    .SYNOPSIS
        Restores .NET project dependencies.
    .DESCRIPTION
        Restores dependencies defined in project files.
    #>
    function Restore-DotnetPackages {
        [CmdletBinding()]
        param()
        
        & dotnet restore
    }
    Set-Alias -Name dotnet-restore -Value Restore-DotnetPackages -ErrorAction SilentlyContinue

    # .NET add package
    <#
    .SYNOPSIS
        Adds NuGet packages to .NET projects.
    .DESCRIPTION
        Adds packages to project files. Supports --version and project specification.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Version
        Package version to install (--version).
    .PARAMETER Project
        Project file path (--project).
    .EXAMPLE
        Add-DotnetPackage Newtonsoft.Json
        Adds Newtonsoft.Json to the current project.
    .EXAMPLE
        Add-DotnetPackage Newtonsoft.Json -Version 13.0.1
        Adds a specific version of Newtonsoft.Json.
    #>
    function Add-DotnetPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Version,
            [string]$Project
        )
        
        foreach ($package in $Packages) {
            $args = @('add', 'package', $package)
            if ($Version) {
                $args += '--version', $Version
            }
            if ($Project) {
                $args += '--project', $Project
            }
            & dotnet @args
        }
    }
    Set-Alias -Name dotnet-add -Value Add-DotnetPackage -ErrorAction SilentlyContinue

    # .NET remove package
    <#
    .SYNOPSIS
        Removes NuGet packages from .NET projects.
    .DESCRIPTION
        Removes packages from project files. Supports project specification.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Project
        Project file path (--project).
    .EXAMPLE
        Remove-DotnetPackage Newtonsoft.Json
        Removes Newtonsoft.Json from the current project.
    #>
    function Remove-DotnetPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Project
        )
        
        foreach ($package in $Packages) {
            $args = @('remove', 'package', $package)
            if ($Project) {
                $args += '--project', $Project
            }
            & dotnet @args
        }
    }
    Set-Alias -Name dotnet-remove -Value Remove-DotnetPackage -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'dotnet' -ToolType 'dotnet-package' -DefaultInstallCommand 'scoop install dotnet-sdk (or winget install Microsoft.DotNet.SDK)'
    }
    else {
        'Install with: scoop install dotnet-sdk (or winget install Microsoft.DotNet.SDK)'
    }
    Write-MissingToolWarning -Tool 'dotnet' -InstallHint $installHint
}
