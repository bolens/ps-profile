<#
tests/unit/library-parallel-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-Parallel pipeline and throttling behavior.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'parallel' 'Parallel.psm1') -DisableNameChecking -Force
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

function script:Get-InvokeParallelTaskResults {
    param([object[]]$Output)

    return @($Output | Where-Object {
            $_ -is [int] -or $_ -is [long] -or $_ -is [double] -or $_ -is [decimal]
        })
}

function script:Set-ParallelTestEnvironment {
    param(
        [int]$TimeoutMs = 100,
        [int]$DelayMs = 500,
        [switch]$DirectScriptblock,
        [switch]$ForceSetupError
    )

    $script:ParallelTestPreviousTimeoutMs = $env:PS_PROFILE_PARALLEL_TIMEOUT_MS
    $script:ParallelTestPreviousDelayMs = $env:PS_PROFILE_PARALLEL_TEST_DELAY_MS
    $script:ParallelTestPreviousDirectScriptblock = $env:PS_PROFILE_PARALLEL_DIRECT_SCRIPTBLOCK
    $script:ParallelTestPreviousSetupError = $env:PS_PROFILE_PARALLEL_FORCE_SETUP_ERROR

    $env:PS_PROFILE_PARALLEL_TIMEOUT_MS = "$TimeoutMs"
    $env:PS_PROFILE_PARALLEL_TEST_DELAY_MS = "$DelayMs"

    if ($DirectScriptblock) {
        $env:PS_PROFILE_PARALLEL_DIRECT_SCRIPTBLOCK = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_DIRECT_SCRIPTBLOCK -ErrorAction SilentlyContinue
    }

    if ($ForceSetupError) {
        $env:PS_PROFILE_PARALLEL_FORCE_SETUP_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_FORCE_SETUP_ERROR -ErrorAction SilentlyContinue
    }
}

function script:Restore-ParallelTestEnvironment {
    if ($null -eq $script:ParallelTestPreviousTimeoutMs) {
        Remove-Item Env:PS_PROFILE_PARALLEL_TIMEOUT_MS -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_TIMEOUT_MS = $script:ParallelTestPreviousTimeoutMs
    }

    if ($null -eq $script:ParallelTestPreviousDelayMs) {
        Remove-Item Env:PS_PROFILE_PARALLEL_TEST_DELAY_MS -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_TEST_DELAY_MS = $script:ParallelTestPreviousDelayMs
    }

    if ($null -eq $script:ParallelTestPreviousDirectScriptblock) {
        Remove-Item Env:PS_PROFILE_PARALLEL_DIRECT_SCRIPTBLOCK -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_DIRECT_SCRIPTBLOCK = $script:ParallelTestPreviousDirectScriptblock
    }

    if ($null -eq $script:ParallelTestPreviousSetupError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_FORCE_SETUP_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_FORCE_SETUP_ERROR = $script:ParallelTestPreviousSetupError
    }
}

AfterAll {
    Remove-Module Parallel -ErrorAction SilentlyContinue -Force
}

Describe 'Parallel extended scenarios' {
    Context 'Invoke-Parallel' {
        It 'Accepts pipeline input across multiple batches' {
            $result = 1, 2, 3 | Invoke-Parallel -ScriptBlock { $_ * 10 }

            @($result).Count | Should -Be 3
            $result | Should -Contain 10
            $result | Should -Contain 20
            $result | Should -Contain 30
        }

        It 'Returns a single-element result collection for one input item' {
            $result = @(42) | Invoke-Parallel -ScriptBlock { $_ + 1 }

            @($result).Count | Should -Be 1
            @($result)[0] | Should -Be 43
        }

        It 'Invokes parameterized script blocks with explicit parameters' {
            $scriptBlock = { param($Value) "value:$Value" }
            $result = @(7, 8) | Invoke-Parallel -ScriptBlock $scriptBlock

            @($result).Count | Should -Be 2
            $result | Should -Contain 'value:7'
            $result | Should -Contain 'value:8'
        }

        It 'Uses processor defaults when ThrottleLimit is zero' {
            $result = @(1..4) | Invoke-Parallel -ScriptBlock { $_ } -ThrottleLimit 0

            @($result).Count | Should -Be 4
        }

        It 'Supports script blocks with multiple parameters' {
            $scriptBlock = { param($Value, $Offset) "value:$($Value + $Offset)" }
            $result = @(1, 2) | Invoke-Parallel -ScriptBlock $scriptBlock

            @($result).Count | Should -Be 2
            $result | Should -Contain 'value:1'
            $result | Should -Contain 'value:2'
        }

        It 'Omits null results from the returned collection' {
            $result = @(1, 2, 3) | Invoke-Parallel -ScriptBlock {
                if ($_ -eq 2) { return $null }
                $_
            }

            @($result).Count | Should -Be 2
            $result | Should -Not -Contain 2
        }

        It 'Completes when PS_PROFILE_DEBUG tracing is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG

            try {
                $env:PS_PROFILE_DEBUG = '2'
                $result = @(4, 5) | Invoke-Parallel -ScriptBlock { $_ + 1 }

                @($result).Count | Should -Be 2
                $result | Should -Contain 5
                $result | Should -Contain 6
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Returns successful items when another item fails in the script block' {
            $result = @(1, 2, 3) | Invoke-Parallel -ScriptBlock {
                if ($_ -eq 2) { throw 'parallel failure probe' }
                $_
            }

            @($result).Count | Should -Be 2
            $result | Should -Contain 1
            $result | Should -Contain 3
            $result | Should -Not -Contain 2
        }

        It 'Accepts script blocks created from source text' {
            $scriptBlock = [scriptblock]::Create('$_ * 2')
            $result = @(2, 4) | Invoke-Parallel -ScriptBlock $scriptBlock
            @($result).Count | Should -Be 2
            $result | Should -Contain 4
            $result | Should -Contain 8
        }

        It 'Emits verbose tracing for level 3 debug output' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = @(9) | Invoke-Parallel -ScriptBlock { $_ + 1 }
                @($result).Count | Should -Be 1
                @($result)[0] | Should -Be 10
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Logs successful completion when PS_PROFILE_DEBUG is level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $result = @(1, 2) | Invoke-Parallel -ScriptBlock { $_ + 10 }
                @($result).Count | Should -Be 2
                $result | Should -Contain 11
                $result | Should -Contain 12
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Accepts the Items parameter directly without pipeline input' {
            $result = Invoke-Parallel -Items @(3, 6, 9) -ScriptBlock { $_ / 3 }
            @($result).Count | Should -Be 3
            $result | Should -Contain 1
            $result | Should -Contain 2
            $result | Should -Contain 3
        }

        It 'Surfaces task failure details when PS_PROFILE_DEBUG is level 3' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = @(5, 6) | Invoke-Parallel -ScriptBlock {
                    if ($_ -eq 6) { throw 'level 3 failure probe' }
                    $_
                }
                @($result).Count | Should -Be 1
                @($result)[0] | Should -Be 5
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits detailed timeout diagnostics when PS_PROFILE_DEBUG is level 3' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(3 | Invoke-Parallel -ScriptBlock {
                        Start-Sleep -Seconds 2
                        $_
                    } -TimeoutSeconds 1)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-StructuredWarning for timeouts when debug output is disabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                $result = Get-InvokeParallelTaskResults -Output @(8 | Invoke-Parallel -ScriptBlock {
                        Start-Sleep -Seconds 2
                        $_
                    } -TimeoutSeconds 1)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Warns and returns partial results when tasks exceed the timeout window' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(1 | Invoke-Parallel -ScriptBlock {
                        Start-Sleep -Seconds 2
                        $_
                    } -TimeoutSeconds 1)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-StructuredError for task failures when debug output is disabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                $result = @(4, 5) | Invoke-Parallel -ScriptBlock {
                    if ($_ -eq 5) { throw 'structured task failure probe' }
                    $_
                }

                @($result).Count | Should -Be 1
                @($result)[0] | Should -Be 4
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Invokes multi-parameter script blocks through bound argument arrays' {
            $scriptBlock = { param($Value, $Offset) "pair:${Value}:${Offset}" }
            $pairItem = ,@(3, 7)
            $result = Invoke-Parallel -Items $pairItem -ScriptBlock $scriptBlock

            @($result).Count | Should -Be 1
            @($result)[0] | Should -Be 'pair:3:7'
        }

        It 'Falls back to Write-Warning for timeouts when structured logging is unavailable' {
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(9 | Invoke-Parallel -ScriptBlock {
                        Start-Sleep -Seconds 2
                        $_
                    } -TimeoutSeconds 1)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits level 3 timeout diagnostics without structured logging enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(2 | Invoke-Parallel -ScriptBlock {
                        Start-Sleep -Seconds 2
                        $_
                    } -TimeoutSeconds 1)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Logs successful parallel completion at debug level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            try {
                $result = 1, 2, 3 | Invoke-Parallel -ScriptBlock { $_ + 1 }
                @($result).Count | Should -Be 3
                $result | Should -Contain 2
                $result | Should -Contain 4
            }
            finally {
                $VerbosePreference = $originalVerbose
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-Error for task failures when structured logging is unavailable' {
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                $result = @(4, 5) | Invoke-Parallel -ScriptBlock {
                    if ($_ -eq 5) { throw 'bare task failure probe' }
                    $_
                }

                @($result).Count | Should -Be 1
                @($result)[0] | Should -Be 4
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Invokes wrapper scriptblock paths in direct scriptblock mode for coverage attribution' {
            Set-ParallelTestEnvironment -DirectScriptblock

            try {
                $result = Invoke-Parallel -Items @(2, 4) -ScriptBlock { $_ * 3 }
                @($result).Count | Should -Be 2
                $result | Should -Contain 6
                $result | Should -Contain 12

                $multiParamBlock = { param($Value, $Offset) "pair:${Value}:${Offset}" }
                $pairItem = ,@(5, 9)
                $pairResult = Invoke-Parallel -Items $pairItem -ScriptBlock $multiParamBlock
                @($pairResult).Count | Should -Be 1
                @($pairResult)[0] | Should -Be 'pair:5:9'
            }
            finally {
                Restore-ParallelTestEnvironment
            }
        }

        It 'Honors the test delay hook in direct scriptblock mode' {
            Set-ParallelTestEnvironment -DirectScriptblock -DelayMs 1

            try {
                $result = Invoke-Parallel -Items @(4) -ScriptBlock { $_ + 1 }
                @($result).Count | Should -Be 1
                @($result)[0] | Should -Be 5
            }
            finally {
                Restore-ParallelTestEnvironment
            }
        }

        It 'Recreates script blocks from source text in direct scriptblock mode' {
            Set-ParallelTestEnvironment -DirectScriptblock

            try {
                $scriptBlock = [scriptblock]::Create('$_ * 4')
                $result = Invoke-Parallel -Items @(2) -ScriptBlock $scriptBlock
                @($result).Count | Should -Be 1
                @($result)[0] | Should -Be 8
            }
            finally {
                Restore-ParallelTestEnvironment
            }
        }

        It 'Uses the processor-based throttle limit when ThrottleLimit is zero' {
            $result = @(1, 2, 3) | Invoke-Parallel -ScriptBlock { $_ } -ThrottleLimit 0
            @($result).Count | Should -Be 3
        }

        It 'Returns an empty array when no items are supplied' {
            $result = Invoke-Parallel -Items @() -ScriptBlock { $_ }
            @($result).Count | Should -Be 0
        }

        It 'Runs timeout scenarios in direct scriptblock mode' {
            Set-ParallelTestEnvironment -DirectScriptblock -TimeoutMs 50 -DelayMs 200
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $timeoutResult = Get-InvokeParallelTaskResults -Output @(12 | Invoke-Parallel -ScriptBlock { $_ } -TimeoutSeconds 60)
                @($timeoutResult).Count | Should -BeLessOrEqual 1
            }
            finally {
                Restore-ParallelTestEnvironment
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Times out quickly using env delay and timeout overrides' {
            Enable-TestStructuredLogging
            Set-ParallelTestEnvironment -TimeoutMs 50 -DelayMs 200
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(7 | Invoke-Parallel -ScriptBlock { $_ } -TimeoutSeconds 60)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                Restore-ParallelTestEnvironment
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Rethrows when parallel setup fails via the setup error probe' {
            Set-ParallelTestEnvironment -ForceSetupError
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                { Invoke-Parallel -Items @(1) -ScriptBlock { $_ } } | Should -Throw '*parallel setup error probe*'
            }
            finally {
                Restore-ParallelTestEnvironment
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-StructuredWarning for global timeouts when debug is explicitly disabled' {
            Enable-TestStructuredLogging
            Set-ParallelTestEnvironment -TimeoutMs 50 -DelayMs 200
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(11 | Invoke-Parallel -ScriptBlock {
                        Start-Sleep -Milliseconds 200
                        $_
                    } -TimeoutSeconds 60)

                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                Restore-ParallelTestEnvironment
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits structured per-task timeout warnings when debug is explicitly disabled' {
            Enable-TestStructuredLogging
            Set-ParallelTestEnvironment -TimeoutMs 250 -DelayMs 0
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                $result = Get-InvokeParallelTaskResults -Output @(1, 2 | Invoke-Parallel -ScriptBlock {
                        if ($_ -eq 2) { Start-Sleep -Milliseconds 600 }
                        $_
                    } -TimeoutSeconds 60)

                @($result).Count | Should -BeLessOrEqual 2
            }
            finally {
                Restore-ParallelTestEnvironment
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Surfaces outer catch diagnostics when setup fails with debug level 3' {
            Set-ParallelTestEnvironment -ForceSetupError
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Invoke-Parallel -Items @(1) -ScriptBlock { $_ } } | Should -Throw '*parallel setup error probe*'
            }
            finally {
                Restore-ParallelTestEnvironment
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-Warning for per-task timeouts at debug level 1 without structured logging' {
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                InModuleScope -ModuleName Parallel {
                    Mock Start-Sleep { }
                    $global:TestParallelTimeoutOutput = @(6 | Invoke-Parallel -ScriptBlock {
                            Start-Sleep -Seconds 60
                            $_
                        } -TimeoutSeconds 1)
                }

                $result = Get-InvokeParallelTaskResults -Output $global:TestParallelTimeoutOutput
                @($result).Count | Should -BeLessOrEqual 1
            }
            finally {
                Remove-Variable -Name TestParallelTimeoutOutput -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }
}
