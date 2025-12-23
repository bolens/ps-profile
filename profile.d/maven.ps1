# ===============================================
# maven.ps1
# Apache Maven build and dependency management
# ===============================================

# Maven aliases and functions
# Requires: mvn (Apache Maven - https://maven.apache.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand mvn) {
    # Maven dependency updates - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Maven dependencies.
    .DESCRIPTION
        Lists all dependencies that have newer versions available.
        This uses the versions-maven-plugin to display dependency updates.
    #>
    function Test-MavenOutdated {
        [CmdletBinding()]
        param()
        
        & mvn versions:display-dependency-updates
    }
    Set-Alias -Name maven-outdated -Value Test-MavenOutdated -ErrorAction SilentlyContinue

    # Maven update dependencies
    <#
    .SYNOPSIS
        Updates Maven dependencies.
    .DESCRIPTION
        Updates dependencies to their latest versions.
        Note: This may require the versions-maven-plugin to be configured.
    #>
    function Update-MavenDependencies {
        [CmdletBinding()]
        param()
        
        & mvn versions:use-latest-versions
    }
    Set-Alias -Name maven-update -Value Update-MavenDependencies -ErrorAction SilentlyContinue

    # Maven dependency:add - add dependencies
    <#
    .SYNOPSIS
        Adds Maven dependencies to project.
    .DESCRIPTION
        Adds dependencies to pom.xml using mvn dependency:add.
        Requires the versions-maven-plugin or manual pom.xml editing.
    .PARAMETER GroupId
        Maven group ID.
    .PARAMETER ArtifactId
        Maven artifact ID.
    .PARAMETER Version
        Dependency version.
    .PARAMETER Scope
        Dependency scope (compile, test, provided, runtime, system).
    .EXAMPLE
        Add-MavenDependency -GroupId org.springframework -ArtifactId spring-core -Version 6.0.0
        Adds Spring Core dependency.
    #>
    function Add-MavenDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$GroupId,
            [Parameter(Mandatory)]
            [string]$ArtifactId,
            [Parameter(Mandatory)]
            [string]$Version,
            [string]$Scope = 'compile'
        )
        
        & mvn dependency:add -DgroupId=$GroupId -DartifactId=$ArtifactId -Dversion=$Version -Dscope=$Scope
    }
    Set-Alias -Name maven-add -Value Add-MavenDependency -ErrorAction SilentlyContinue

    # Maven dependency:remove - remove dependencies
    <#
    .SYNOPSIS
        Removes Maven dependencies from project.
    .DESCRIPTION
        Removes dependencies from pom.xml using mvn dependency:remove.
    .PARAMETER GroupId
        Maven group ID.
    .PARAMETER ArtifactId
        Maven artifact ID.
    .EXAMPLE
        Remove-MavenDependency -GroupId org.springframework -ArtifactId spring-core
        Removes Spring Core dependency.
    #>
    function Remove-MavenDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$GroupId,
            [Parameter(Mandatory)]
            [string]$ArtifactId
        )
        
        & mvn dependency:remove -DgroupId=$GroupId -DartifactId=$ArtifactId
    }
    Set-Alias -Name maven-remove -Value Remove-MavenDependency -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'mvn' -InstallHint 'Install Maven from: https://maven.apache.org/download.cgi or use: scoop install maven'
}
