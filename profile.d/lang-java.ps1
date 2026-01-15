# ===============================================
# lang-java.ps1
# Java development tools (enhanced)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Java development tools fragment for enhanced Java development workflows.

.DESCRIPTION
    Provides wrapper functions for Java development tools:
    - Maven: Build tool for Java projects
    - Gradle: Build tool for Java projects
    - Ant: Build tool for Java projects
    - Kotlin: Kotlin compiler
    - Scala: Scala compiler
    - Java version management: Switch between Java versions

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides enhanced Java development tooling.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-java') { return }
    }

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

    if (-not (Test-Path Function:\Build-Maven -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Build-Maven' -Body ${function:Build-Maven}
    }
    if (-not (Get-Alias mvn -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'mvn' -Target 'Build-Maven'
        }
        else {
            Set-Alias -Name 'mvn' -Value 'Build-Maven' -ErrorAction SilentlyContinue
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

    if (-not (Test-Path Function:\Build-Gradle -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Build-Gradle' -Body ${function:Build-Gradle}
    }
    if (-not (Get-Alias gradle -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'gradle' -Target 'Build-Gradle'
        }
        else {
            Set-Alias -Name 'gradle' -Value 'Build-Gradle' -ErrorAction SilentlyContinue
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

    if (-not (Test-Path Function:\Build-Ant -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Build-Ant' -Body ${function:Build-Ant}
    }
    if (-not (Get-Alias ant -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'ant' -Target 'Build-Ant'
        }
        else {
            Set-Alias -Name 'ant' -Value 'Build-Ant' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Kotlin - Compiler
    # ===============================================

    <#
    .SYNOPSIS
        Compiles Kotlin code.

    .DESCRIPTION
        Wrapper function for the Kotlin compiler (kotlinc).

    .PARAMETER Arguments
        Additional arguments to pass to kotlinc.
        Can be used multiple times or as an array.

    .EXAMPLE
        Compile-Kotlin Main.kt
        Compiles Main.kt.

    .EXAMPLE
        Compile-Kotlin -include-runtime -d app.jar Main.kt
        Compiles with runtime included into a JAR.

    .OUTPUTS
        System.String. Output from Kotlin compiler execution.
    #>
    function Compile-Kotlin {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'kotlinc')) {
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
                Get-ToolInstallHint -ToolName 'kotlin' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install kotlin"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kotlinc' -InstallHint $installHint
            }
            else {
                Write-Warning "kotlinc not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.kotlin.compile' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & kotlinc @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & kotlinc @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run kotlinc: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Compile-Kotlin -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Compile-Kotlin' -Body ${function:Compile-Kotlin}
    }
    if (-not (Get-Alias kotlinc -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'kotlinc' -Target 'Compile-Kotlin'
        }
        else {
            Set-Alias -Name 'kotlinc' -Value 'Compile-Kotlin' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Scala - Compiler
    # ===============================================

    <#
    .SYNOPSIS
        Compiles Scala code.

    .DESCRIPTION
        Wrapper function for the Scala compiler (scalac).

    .PARAMETER Arguments
        Additional arguments to pass to scalac.
        Can be used multiple times or as an array.

    .EXAMPLE
        Compile-Scala Main.scala
        Compiles Main.scala.

    .EXAMPLE
        Compile-Scala -d classes Main.scala
        Compiles to a specific output directory.

    .OUTPUTS
        System.String. Output from Scala compiler execution.
    #>
    function Compile-Scala {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'scalac')) {
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
                Get-ToolInstallHint -ToolName 'scala' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install scala"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'scalac' -InstallHint $installHint
            }
            else {
                Write-Warning "scalac not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.scala.compile' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & scalac @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & scalac @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run scalac: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Compile-Scala -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Compile-Scala' -Body ${function:Compile-Scala}
    }
    if (-not (Get-Alias scalac -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'scalac' -Target 'Compile-Scala'
        }
        else {
            Set-Alias -Name 'scalac' -Value 'Compile-Scala' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Java Version Management
    # ===============================================

    <#
    .SYNOPSIS
        Switches Java version using JAVA_HOME.

    .DESCRIPTION
        Helper function to switch Java versions by setting JAVA_HOME environment variable.
        This is a simple wrapper that sets JAVA_HOME to point to a specific Java installation.

    .PARAMETER Version
        Java version to switch to (e.g., '17', '21', '11').
        If not specified, displays current Java version.

    .PARAMETER JavaHome
        Full path to Java installation directory.
        If not specified, attempts to find Java in common locations.

    .EXAMPLE
        Set-JavaVersion -Version 17
        Switches to Java 17 (if available).

    .EXAMPLE
        Set-JavaVersion -JavaHome "C:\Program Files\Java\jdk-17"
        Sets JAVA_HOME to the specified path.

    .OUTPUTS
        System.String. Current Java version information.
    #>
    function Set-JavaVersion {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Version,

            [Parameter()]
            [string]$JavaHome
        )

        # If no parameters, show current Java version
        if (-not $Version -and -not $JavaHome) {
            # First check if JAVA_HOME or JRE_HOME is already set
            if ($env:JAVA_HOME -and (Test-Path -LiteralPath $env:JAVA_HOME -PathType Container)) {
                Write-Host "JAVA_HOME is set to: $env:JAVA_HOME" -ForegroundColor Cyan
            }
            if ($env:JRE_HOME -and (Test-Path -LiteralPath $env:JRE_HOME -PathType Container)) {
                Write-Host "JRE_HOME is set to: $env:JRE_HOME" -ForegroundColor Cyan
            }
            if ($env:JDK_HOME -and (Test-Path -LiteralPath $env:JDK_HOME -PathType Container)) {
                Write-Host "JDK_HOME is set to: $env:JDK_HOME" -ForegroundColor Cyan
            }
            
            if (Test-CachedCommand 'java') {
                try {
                    $versionOutput = & java -version 2>&1
                    return $versionOutput
                }
                catch {
                    Write-Warning "Failed to get Java version: $($_.Exception.Message)"
                    return $null
                }
            }
            else {
                Write-Warning "Java not found in PATH. Set JAVA_HOME or install Java."
                return $null
            }
        }

        # If JavaHome is specified, use it directly
        if ($JavaHome) {
            if (Test-Path -LiteralPath $JavaHome -PathType Container) {
                $env:JAVA_HOME = $JavaHome
                $env:PATH = "$JavaHome\bin;$env:PATH"
                Write-Host "JAVA_HOME set to: $JavaHome" -ForegroundColor Green
                return "JAVA_HOME set to: $JavaHome"
            }
            else {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.DirectoryNotFoundException]::new("Java installation not found at: $JavaHome"),
                        'JavaHomeNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $JavaHome
                    )) -OperationName 'java.version.set' -Context @{ java_home = $JavaHome }
                }
                else {
                    Write-Error "Java installation not found at: $JavaHome"
                }
                return $null
            }
        }

        # If Version is specified, try to find it
        if ($Version) {
            # First, check standard environment variables (highest priority)
            # Check if existing JAVA_HOME matches the requested version
            if ($env:JAVA_HOME -and (Test-Path -LiteralPath $env:JAVA_HOME -PathType Container)) {
                $javaExe = Join-Path $env:JAVA_HOME 'bin' 'java.exe'
                if (Test-Path -LiteralPath $javaExe) {
                    try {
                        $currentVersion = & $javaExe -version 2>&1 | Select-String -Pattern "version `"(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                        if ($currentVersion -eq $Version) {
                            Write-Host "Java $Version already set via JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
                            return "Java $Version already set via JAVA_HOME: $env:JAVA_HOME"
                        }
                    }
                    catch {
                        # Ignore version check errors, continue searching
                    }
                }
            }
            
            # Check other Java-related environment variables that packages might set
            $javaEnvVars = @('JRE_HOME', 'JDK_HOME', 'JAVA_ROOT', 'JAVA_PATH')
            foreach ($envVar in $javaEnvVars) {
                $envValue = (Get-Variable -Name "env:$envVar" -ErrorAction SilentlyContinue).Value
                if ($envValue -and (Test-Path -LiteralPath $envValue -PathType Container)) {
                    $javaExe = Join-Path $envValue 'bin' 'java.exe'
                    if (Test-Path -LiteralPath $javaExe) {
                        try {
                            $currentVersion = & $javaExe -version 2>&1 | Select-String -Pattern "version `"(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                            if ($currentVersion -eq $Version) {
                                Write-Host "Java $Version found via ${envVar}: $envValue" -ForegroundColor Green
                                $env:JAVA_HOME = $envValue
                                $env:PATH = "$envValue\bin;$env:PATH"
                                return "Java $Version set via ${envVar}: $envValue"
                            }
                        }
                        catch {
                            # Ignore version check errors, continue searching
                        }
                    }
                }
            }
            
            $commonPaths = @()
            
            # Standard Java installation paths
            $commonPaths += "$env:ProgramFiles\Java\jdk-$Version"
            $commonPaths += "$env:ProgramFiles\Java\jdk-$Version*"
            
            # ProgramFiles(x86) if it exists
            $programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
            if ($programFilesX86) {
                $commonPaths += "$programFilesX86\Java\jdk-$Version"
                $commonPaths += "$programFilesX86\Java\jdk-$Version*"
            }
            
            # Eclipse Adoptium (Temurin) paths
            $commonPaths += "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-$Version*"
            $commonPaths += "$env:ProgramFiles\Eclipse Adoptium\jdk-$Version*"
            
            # Microsoft OpenJDK paths
            $commonPaths += "$env:ProgramFiles\Microsoft\jdk-$Version"
            $commonPaths += "$env:ProgramFiles\Microsoft\jdk-$Version*"
            
            # Scoop installation paths (if Scoop is installed)
            $scoopRoot = $null
            if (Get-Command Get-ScoopRoot -ErrorAction SilentlyContinue) {
                $scoopRoot = Get-ScoopRoot
            }
            else {
                # Fallback: Try common Scoop locations
                $scoopRoot = $env:SCOOP
                if (-not $scoopRoot) {
                    if ($env:USERPROFILE) {
                        $scoopRoot = Join-Path $env:USERPROFILE 'scoop'
                    }
                    if (-not (Test-Path -LiteralPath $scoopRoot -ErrorAction SilentlyContinue)) {
                        if ($env:LOCALAPPDATA) {
                            $scoopRoot = Join-Path $env:LOCALAPPDATA 'scoop'
                        }
                    }
                }
            }
            
            if ($scoopRoot -and (Test-Path -LiteralPath $scoopRoot -ErrorAction SilentlyContinue)) {
                # Temurin JDK (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jdk' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jdk' "*$Version*")
                
                # Temurin JRE (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jre' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jre' "*$Version*")
                
                # Microsoft OpenJDK (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjdk' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjdk' "*$Version*")
                
                # Microsoft OpenJRE (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjre' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjre' "*$Version*")
            }
            
            # Chocolatey installation paths (if Chocolatey is installed)
            $chocoRoot = $null
            if (Get-Command Get-ChocolateyRoot -ErrorAction SilentlyContinue) {
                $chocoRoot = Get-ChocolateyRoot
            }
            else {
                # Fallback: Try common Chocolatey locations
                $chocoRoot = $env:ChocolateyInstall
                if (-not $chocoRoot) {
                    if ($env:ProgramData) {
                        $chocoRoot = Join-Path $env:ProgramData 'chocolatey'
                    }
                    if (-not (Test-Path -LiteralPath $chocoRoot -ErrorAction SilentlyContinue)) {
                        $chocoRoot = 'C:\ProgramData\chocolatey'
                    }
                }
            }
            
            if ($chocoRoot -and (Test-Path -LiteralPath $chocoRoot -ErrorAction SilentlyContinue)) {
                # Get Chocolatey lib directory
                $chocoLib = $null
                if (Get-Command Get-ChocolateyLibPath -ErrorAction SilentlyContinue) {
                    $chocoLib = Get-ChocolateyLibPath -ChocolateyRoot $chocoRoot
                }
                else {
                    $chocoLib = Join-Path $chocoRoot 'lib'
                }
                
                if ($chocoLib -and (Test-Path -LiteralPath $chocoLib -PathType Container)) {
                    # Look for JDK packages (temurin, microsoft-openjdk, etc.)
                    $commonPaths += (Join-Path $chocoLib "temurin*$Version*")
                    $commonPaths += (Join-Path $chocoLib "microsoft-openjdk*$Version*")
                    $commonPaths += (Join-Path $chocoLib "openjdk*$Version*")
                    $commonPaths += (Join-Path $chocoLib "jdk*$Version*")
                }
            }

            $foundPath = $null
            foreach ($path in $commonPaths) {
                if (Test-Path -LiteralPath $path -PathType Container) {
                    $foundPath = $path
                    break
                }
                # Try wildcard matching
                $parentPath = Split-Path -Parent $path
                $filter = Split-Path -Leaf $path
                if (Test-Path -LiteralPath $parentPath -PathType Container) {
                    $wildcardPaths = Get-ChildItem -Path $parentPath -Filter $filter -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
                    if ($wildcardPaths) {
                        $foundPath = $wildcardPaths[0].FullName
                        break
                    }
                }
            }

            if ($foundPath) {
                $env:JAVA_HOME = $foundPath
                $env:PATH = "$foundPath\bin;$env:PATH"
                Write-Host "Switched to Java $Version at: $foundPath" -ForegroundColor Green
                return "Switched to Java $Version at: $foundPath"
            }
            else {
                Write-Warning "Java $Version not found in common locations. Use -JavaHome to specify the path."
                return $null
            }
        }

        return $null
    }

    if (-not (Test-Path Function:\Set-JavaVersion -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Set-JavaVersion' -Body ${function:Set-JavaVersion}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-java'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-java' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-java fragment: $($_.Exception.Message)"
    }
}
