# ===============================================
# swift.ps1
# Swift Package Manager
# ===============================================

# Swift Package Manager aliases and functions
# Requires: swift (Swift - https://swift.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand swift) {
    # Swift package update
    <#
    .SYNOPSIS
        Updates Swift package dependencies.
    .DESCRIPTION
        Updates all package dependencies to their latest versions within version constraints.
        This is equivalent to running 'swift package update'.
    #>
    function Update-SwiftPackages {
        [CmdletBinding()]
        param()
        
        & swift package update
    }
    Set-Alias -Name swift-update -Value Update-SwiftPackages -ErrorAction SilentlyContinue

    # Swift package resolve
    <#
    .SYNOPSIS
        Resolves Swift package dependencies.
    .DESCRIPTION
        Resolves package dependencies to their exact versions.
    #>
    function Resolve-SwiftPackages {
        [CmdletBinding()]
        param()
        
        & swift package resolve
    }
    Set-Alias -Name swift-resolve -Value Resolve-SwiftPackages -ErrorAction SilentlyContinue

    # Swift package add - add dependencies
    <#
    .SYNOPSIS
        Adds Swift package dependencies.
    .DESCRIPTION
        Note: Swift Package Manager dependencies are typically added via Xcode or by editing Package.swift.
        This function provides guidance for manual addition.
    .PARAMETER URL
        Package repository URL.
    .PARAMETER Version
        Package version requirement.
    .EXAMPLE
        Add-SwiftPackage -URL https://github.com/apple/swift-algorithms.git -Version '1.0.0'
        Provides instructions for adding Swift Algorithms package.
    #>
    function Add-SwiftPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$URL,
            [string]$Version
        )
        
        Write-Warning "Swift Package Manager dependencies are added via Package.swift. Add to dependencies:"
        Write-Output ".package(url: `"$URL`""
        if ($Version) {
            Write-Output ", from: `"$Version`""
        }
        Write-Output ")"
    }
    Set-Alias -Name swift-add -Value Add-SwiftPackage -ErrorAction SilentlyContinue

    # Swift package remove - remove dependencies (manual Package.swift editing required)
    <#
    .SYNOPSIS
        Removes Swift package dependencies.
    .DESCRIPTION
        Note: Swift Package Manager dependencies are removed by editing Package.swift.
        This function provides guidance.
    .PARAMETER URL
        Package repository URL to remove.
    .EXAMPLE
        Remove-SwiftPackage -URL https://github.com/apple/swift-algorithms.git
        Provides instructions for removing Swift Algorithms package.
    #>
    function Remove-SwiftPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$URL
        )
        
        Write-Warning "Swift Package Manager dependencies are removed from Package.swift. Remove:"
        Write-Output ".package(url: `"$URL`", ...)"
        Write-Output "Then run: swift package resolve"
    }
    Set-Alias -Name swift-remove -Value Remove-SwiftPackage -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'swift' -InstallHint 'Install Swift from: https://swift.org/download/ or use: scoop install swift'
}
