# ===============================================
# maven.ps1
# Apache Maven build and dependency management
# ===============================================

# Maven aliases and functions
# Requires: mvn (Apache Maven - https://maven.apache.org/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand mvn)) {
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
    Set-AgentModeAlias -Name 'maven-outdated' -Target 'Test-MavenOutdated'
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
    Set-AgentModeAlias -Name 'maven-update' -Target 'Update-MavenDependencies'
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
    Set-AgentModeAlias -Name 'maven-add' -Target 'Add-MavenDependency'
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
    Set-AgentModeAlias -Name 'maven-remove' -Target 'Remove-MavenDependency'
}
else {
    Write-MissingToolWarning -Tool 'mvn' -InstallHint 'Install Maven from: https://maven.apache.org/download.cgi or use: scoop install maven'
}
