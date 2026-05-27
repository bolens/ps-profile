# ===============================================
# lang-java-compilers.ps1
# JVM language compilers (Kotlin, Scala)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    JVM language compilers (Kotlin, Scala).

.DESCRIPTION
    Provides wrapper functions for Java development tools:
    - Kotlin: Kotlin compiler (kotlinc)
    - Scala: Scala compiler (scalac)

.NOTES
    All functions gracefully degrade when tools are not installed.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-java-compilers') { return }
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

    Set-AgentModeFunction -Name 'Compile-Kotlin' -Body ${function:Compile-Kotlin}
    if (-not (Get-Alias kotlinc -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'kotlinc' -Target 'Compile-Kotlin'
        }
        else {
            Set-AgentModeAlias -Name 'kotlinc' -Target 'Compile-Kotlin'
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

    Set-AgentModeFunction -Name 'Compile-Scala' -Body ${function:Compile-Scala}
    if (-not (Get-Alias scalac -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'scalac' -Target 'Compile-Scala'
        }
        else {
            Set-AgentModeAlias -Name 'scalac' -Target 'Compile-Scala'
        }
    }
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-java-compilers'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-java-compilers' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-java-compilers fragment: $($_.Exception.Message)"
    }
}
