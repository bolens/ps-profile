<#
tests/unit/library-retry-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Retry callback resilience and pattern matching.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'core' 'Retry.psm1') -DisableNameChecking -Force
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

AfterAll {
    Remove-Module Retry -ErrorAction SilentlyContinue -Force
}

Describe 'Retry extended scenarios' {
    Context 'Invoke-WithRetry' {
        It 'Continues retrying when the OnRetry callback throws' {
            $script:attemptCounter = 0

            $result = Invoke-WithRetry -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 2) {
                    throw 'transient failure'
                }

                return 'recovered'
            } -MaxRetries 2 -RetryDelaySeconds 0 -OnRetry {
                throw 'callback failure'
            }

            $result | Should -Be 'recovered'
            $script:attemptCounter | Should -Be 2
        }

        It 'Fails after a single attempt when MaxRetries is zero' {
            $script:attemptCounter = 0

            {
                Invoke-WithRetry -ScriptBlock {
                    $script:attemptCounter++
                    throw 'immediate failure'
                } -MaxRetries 0 -RetryDelaySeconds 0 -ErrorAction SilentlyContinue
            } | Should -Throw

            $script:attemptCounter | Should -Be 1
        }
    }

    Context 'Test-IsRetryableError' {
        It 'Treats busy and locked messages as retryable' {
            Test-IsRetryableError -Exception ([Exception]::new('Resource is busy')) | Should -Be $true
            Test-IsRetryableError -Exception ([Exception]::new('File is locked by another process')) | Should -Be $true
        }
    }

    Context 'Get-RetryDelay' {
        It 'Calculates exponential delay for later attempts' {
            $delay = Get-RetryDelay -Attempt 4 -BaseDelaySeconds 1 -ExponentialBackoff

            $delay | Should -Be 8
        }
    }

    Context 'Invoke-WithRetry debug and logging' {
        It 'Emits verbose tracing when PS_PROFILE_DEBUG is level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            try {
                $result = Invoke-WithRetry -ScriptBlock { 'debug-success' } -MaxRetries 1 -RetryDelaySeconds 0
                $result | Should -Be 'debug-success'
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

        It 'Emits level 3 retry diagnostics when retries occur' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'
            $script:attemptCounter = 0

            try {
                $result = Invoke-WithRetry -ScriptBlock {
                    $script:attemptCounter++
                    if ($script:attemptCounter -lt 2) {
                        throw 'level 3 retry probe'
                    }

                    return 'recovered'
                } -MaxRetries 2 -RetryDelaySeconds 0 -ExponentialBackoff

                $result | Should -Be 'recovered'
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

        It 'Uses Write-StructuredError when final retry fails and structured logging is enabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                {
                    Invoke-WithRetry -ScriptBlock { throw 'structured final failure probe' } -MaxRetries 1 -RetryDelaySeconds 0
                } | Should -Throw
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

        It 'Uses Write-Error when final retry fails without structured logging' {
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                {
                    Invoke-WithRetry -ScriptBlock { throw 'bare final failure probe' } -MaxRetries 1 -RetryDelaySeconds 0
                } | Should -Throw
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

        It 'Logs retry attempts through Write-ScriptMessage when Logging module is available' {
            $loggingPath = Join-Path $script:LibPath 'core' 'Logging.psm1'
            Import-Module $loggingPath -DisableNameChecking -Force -ErrorAction SilentlyContinue

            $script:attemptCounter = 0
            try {
                $result = Invoke-WithRetry -ScriptBlock {
                    $script:attemptCounter++
                    if ($script:attemptCounter -lt 2) {
                        throw 'logging retry probe'
                    }

                    return 'logged-recovery'
                } -MaxRetries 2 -RetryDelaySeconds 0

                $result | Should -Be 'logged-recovery'
            }
            finally {
                Remove-Module Logging -ErrorAction SilentlyContinue -Force
            }
        }

        It 'Emits level 3 failure diagnostics when retries are exhausted' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                {
                    Invoke-WithRetry -ScriptBlock { throw 'level 3 final failure probe' } -MaxRetries 1 -RetryDelaySeconds 0
                } | Should -Throw
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

        It 'Uses structured errors when debug is explicitly disabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                {
                    Invoke-WithRetry -ScriptBlock { throw 'structured debug-off probe' } -MaxRetries 0 -RetryDelaySeconds 0
                } | Should -Throw
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

        It 'Does not retry when RetryCondition rejects the error' {
            $script:attemptCounter = 0
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                {
                    Invoke-WithRetry -ScriptBlock {
                        $script:attemptCounter++
                        throw 'permanent retry probe'
                    } -MaxRetries 3 -RetryDelaySeconds 0 -RetryCondition {
                        param($ErrorRecord)
                        $ErrorRecord.Exception.Message -match 'timeout'
                    }
                } | Should -Throw

                $script:attemptCounter | Should -Be 1
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

        It 'Emits retry verbose output when PS_PROFILE_DEBUG is level 2' {
            $script:attemptCounter = 0
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            try {
                $result = Invoke-WithRetry -ScriptBlock {
                    $script:attemptCounter++
                    if ($script:attemptCounter -lt 2) {
                        throw 'retry verbose probe'
                    }

                    return 'retry-verbose-success'
                } -MaxRetries 2 -RetryDelaySeconds 0

                $result | Should -Be 'retry-verbose-success'
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
    }
}
