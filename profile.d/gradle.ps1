# ===============================================
# gradle.ps1
# Gradle build and dependency management
# ===============================================

# Gradle aliases and functions
# Requires: gradle (Gradle - https://gradle.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand gradle) {
    # Gradle dependency updates - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Gradle dependencies.
    .DESCRIPTION
        Lists all dependencies that have newer versions available.
        This requires the gradle-versions-plugin to be configured in build.gradle.
    #>
    function Test-GradleOutdated {
        [CmdletBinding()]
        param()
        
        & gradle dependencyUpdates
    }
    Set-Alias -Name gradle-outdated -Value Test-GradleOutdated -ErrorAction SilentlyContinue

    # Gradle update dependencies
    <#
    .SYNOPSIS
        Updates Gradle wrapper to latest version.
    .DESCRIPTION
        Updates the Gradle wrapper to the latest version.
    #>
    function Update-GradleWrapper {
        [CmdletBinding()]
        param()
        
        & gradle wrapper --gradle-version latest
    }
    Set-Alias -Name gradle-wrapper-update -Value Update-GradleWrapper -ErrorAction SilentlyContinue

    # Gradle add dependency - add dependencies (manual build.gradle editing required)
    <#
    .SYNOPSIS
        Adds Gradle dependencies to project.
    .DESCRIPTION
        Note: Gradle doesn't have a direct CLI command to add dependencies.
        This function provides guidance. Dependencies are typically added manually to build.gradle.
    .PARAMETER Configuration
        Configuration name (implementation, testImplementation, etc.).
    .PARAMETER Dependency
        Dependency notation (e.g., 'org.springframework:spring-core:6.0.0').
    .EXAMPLE
        Add-GradleDependency -Configuration implementation -Dependency 'org.springframework:spring-core:6.0.0'
        Provides instructions for adding Spring Core dependency.
    #>
    function Add-GradleDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Configuration,
            [Parameter(Mandatory)]
            [string]$Dependency
        )
        
        Write-Warning "Gradle doesn't support adding dependencies via CLI. Add to build.gradle:"
        Write-Output "$Configuration '$Dependency'"
        Write-Output "Then run: gradle build --refresh-dependencies"
    }
    Set-Alias -Name gradle-add -Value Add-GradleDependency -ErrorAction SilentlyContinue

    # Gradle remove dependency - remove dependencies (manual build.gradle editing required)
    <#
    .SYNOPSIS
        Removes Gradle dependencies from project.
    .DESCRIPTION
        Note: Gradle doesn't have a direct CLI command to remove dependencies.
        This function provides guidance. Dependencies are typically removed manually from build.gradle.
    .PARAMETER Dependency
        Dependency notation to remove.
    .EXAMPLE
        Remove-GradleDependency 'org.springframework:spring-core:6.0.0'
        Provides instructions for removing Spring Core dependency.
    #>
    function Remove-GradleDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Dependency
        )
        
        Write-Warning "Gradle doesn't support removing dependencies via CLI. Remove from build.gradle:"
        Write-Output "Remove line containing: $Dependency"
        Write-Output "Then run: gradle build --refresh-dependencies"
    }
    Set-Alias -Name gradle-remove -Value Remove-GradleDependency -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'gradle' -InstallHint 'Install Gradle from: https://gradle.org/install/ or use: scoop install gradle'
}
