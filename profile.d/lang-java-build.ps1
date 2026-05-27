# ===============================================
# lang-java-build.ps1
# Java build tools (Maven, Gradle, Ant)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Java build tools (Maven, Gradle, Ant).

.DESCRIPTION
    Provides wrapper functions for Java development tools:
    - Maven: Build tool for Java projects
    - Gradle: Build tool for Java projects
    - Ant: Build tool for Java projects

.NOTES
    All functions gracefully degrade when tools are not installed.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-java-build') { return }
    }

    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                # Get-RepoRoot expects scripts/ subdirectory, but we're in profile.d/
                # Fall back to manual path resolution
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }

        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    }
    # ===============================================
    # Maven - Build tool
    # ===============================================

    <#
    .SYNOPSIS
        Builds Java projects using Maven.

    .DESCRIPTION
        Wrapper function for Maven, a build automation tool for Java projects.

    .PARAMETER Arguments
        Additional arguments to pass to mvn.
        Can be used multiple times or as an array.

    .EXAMPLE
        Build-Maven
        Builds the current Maven project.

    .EXAMPLE
        Build-Maven clean install
        Cleans and installs the project.

    .EXAMPLE
        Build-Maven test
        Runs Maven tests.

    .OUTPUTS
        System.String. Output from Maven execution.
    #>
    function Build-Maven {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'mvn')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'maven' -ToolType 'java-build-tool'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'maven' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install maven"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'mvn' -InstallHint $installHint
            }
            else {
                Write-Warning "mvn not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.maven.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & mvn @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & mvn @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run mvn: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Build-Maven' -Body ${function:Build-Maven}
    if (-not (Get-Alias mvn -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'mvn' -Target 'Build-Maven'
        }
        else {
            Set-AgentModeAlias -Name 'mvn' -Target 'Build-Maven'
        }
    }

    # ===============================================
    # Gradle - Build tool
    # ===============================================

    <#
    .SYNOPSIS
        Builds Java projects using Gradle.

    .DESCRIPTION
        Wrapper function for Gradle, a build automation tool for Java projects.

    .PARAMETER Arguments
        Additional arguments to pass to gradle.
        Can be used multiple times or as an array.

    .EXAMPLE
        Build-Gradle
        Builds the current Gradle project.

    .EXAMPLE
        Build-Gradle build
        Builds the project.

    .EXAMPLE
        Build-Gradle test
        Runs Gradle tests.

    .OUTPUTS
        System.String. Output from Gradle execution.
    #>
    function Build-Gradle {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'gradle')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'gradle' -ToolType 'java-build-tool'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'gradle' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install gradle"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'gradle' -InstallHint $installHint
            }
            else {
                Write-Warning "gradle not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.gradle.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & gradle @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & gradle @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run gradle: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Build-Gradle' -Body ${function:Build-Gradle}
    if (-not (Get-Alias gradle -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'gradle' -Target 'Build-Gradle'
        }
        else {
            Set-AgentModeAlias -Name 'gradle' -Target 'Build-Gradle'
        }
    }

    # ===============================================
    # Ant - Build tool
    # ===============================================

    <#
    .SYNOPSIS
        Builds Java projects using Apache Ant.

    .DESCRIPTION
        Wrapper function for Apache Ant, a build tool for Java projects.

    .PARAMETER Arguments
        Additional arguments to pass to ant.
        Can be used multiple times or as an array.

    .EXAMPLE
        Build-Ant
        Builds the current Ant project.

    .EXAMPLE
        Build-Ant clean
        Cleans the project.

    .EXAMPLE
        Build-Ant test
        Runs Ant tests.

    .OUTPUTS
        System.String. Output from Ant execution.
    #>
    function Build-Ant {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'ant')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'ant' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install ant"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'ant' -InstallHint $installHint
            }
            else {
                Write-Warning "ant not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.ant.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & ant @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & ant @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run ant: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Build-Ant' -Body ${function:Build-Ant}
    if (-not (Get-Alias ant -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'ant' -Target 'Build-Ant'
        }
        else {
            Set-AgentModeAlias -Name 'ant' -Target 'Build-Ant'
        }
    }
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-java-build'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-java-build' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-java-build fragment: $($_.Exception.Message)"
    }
}
