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

        $kotlincCmd = if (Test-CachedCommand 'kotlinc') { Get-CachedExternalCommand 'kotlinc' } else { $null }
        if (-not $kotlincCmd) {
            Invoke-MissingToolWarning -ToolName 'kotlin' -ToolType 'java-build-tool' -Tool 'kotlinc'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.kotlin.compile' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & $kotlincCmd @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & $kotlincCmd @Arguments 2>&1
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

        $scalacCmd = if (Test-CachedCommand 'scalac') { Get-CachedExternalCommand 'scalac' } else { $null }
        if (-not $scalacCmd) {
            Invoke-MissingToolWarning -ToolName 'scala' -ToolType 'java-build-tool' -Tool 'scalac'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'java.scala.compile' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & $scalacCmd @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & $scalacCmd @Arguments 2>&1
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
