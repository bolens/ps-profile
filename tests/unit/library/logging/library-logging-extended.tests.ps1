<#
tests/unit/library-logging-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Write-ScriptMessage structured logging and log files.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Logging.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'LoggingExtended'
}

AfterAll {
    Remove-Module Logging -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Logging extended scenarios' {
    Context 'Write-ScriptMessage structured output' {
        It 'Emits parseable JSON with Message, Level, and Timestamp fields' {
            $output = Write-ScriptMessage -Message 'Structured payload' -StructuredOutput 6>&1
            $json = $output | ConvertFrom-Json

            $json.Message | Should -Be 'Structured payload'
            $json.Level | Should -Be 'Info'
            $json.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Uses Warning level in structured JSON output' {
            $output = Write-ScriptMessage -Message 'Structured warning' -LogLevel Warning -StructuredOutput 6>&1
            $json = $output | ConvertFrom-Json

            $json.Level | Should -Be 'Warning'
        }

        It 'Writes structured JSON entries to log files' {
            $logFile = Join-Path $script:TempDir 'structured.log'
            Write-ScriptMessage -Message 'File structured entry' -LogLevel Info -StructuredOutput -LogFile $logFile

            $content = Get-Content -LiteralPath $logFile -Raw
            $json = $content | ConvertFrom-Json
            $json.Message | Should -Be 'File structured entry'
        }
    }

    Context 'Write-ScriptMessage log file levels' {
        It 'Includes Warning level markers in plain log files' {
            $logFile = Join-Path $script:TempDir 'warning.log'
            Write-ScriptMessage -Message 'Warning entry' -LogLevel Warning -LogFile $logFile

            $content = Get-Content -LiteralPath $logFile -Raw
            $content | Should -Match '\[Warning\]'
            $content | Should -Match 'Warning entry'
        }

        It 'Creates nested directories when writing log files' {
            $logFile = Join-Path $script:TempDir 'nested' 'deep' 'created.log'
            Write-ScriptMessage -Message 'Nested log write' -LogFile $logFile

            Test-Path -LiteralPath $logFile | Should -Be $true
        }

        It 'Rotates oversized log files on overwrite writes' {
            $logFile = Join-Path $script:TempDir 'overwrite-rotation.log'
            $largeMessage = 'Y' * (1024 * 1024)
            Write-ScriptMessage -Message $largeMessage -LogFile $logFile -MaxLogFileSizeMB 1
            Write-ScriptMessage -Message 'after rotation' -LogFile $logFile -MaxLogFileSizeMB 1

            Test-Path -LiteralPath $logFile | Should -Be $true
            $rotated = "$logFile.1"
            if (Test-Path -LiteralPath $rotated) {
                Test-Path -LiteralPath $rotated | Should -Be $true
            }
        }
    }

    Context 'Logging test environment hooks' {
        It 'Uses plain warnings when structured logging is disabled for log file failures' {
            $logFile = Join-Path $script:TempDir 'forced-failure.log'
            $originalWriteFlag = $env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR
            $originalStructuredFlag = $env:PS_PROFILE_LOGGING_DISABLE_STRUCTURED_WARNING
            $env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR = '1'
            $env:PS_PROFILE_LOGGING_DISABLE_STRUCTURED_WARNING = '1'

            try {
                { Write-ScriptMessage -Message 'probe' -LogFile $logFile } | Should -Not -Throw
            }
            finally {
                if ($null -eq $originalWriteFlag) {
                    Remove-Item Env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR = $originalWriteFlag
                }

                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_LOGGING_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_LOGGING_DISABLE_STRUCTURED_WARNING = $originalStructuredFlag
                }
            }
        }

        It 'Emits structured warnings for log file failures when available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) {
                . $globalState
            }
            if (Test-Path -LiteralPath $functionRegistration) {
                . $functionRegistration
            }
            if (Test-Path -LiteralPath $errorHandlingPath) {
                . $errorHandlingPath
            }

            $logFile = Join-Path $script:TempDir 'structured-failure.log'
            $originalWriteFlag = $env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Write-ScriptMessage -Message 'probe' -LogFile $logFile } | Should -Not -Throw
            }
            finally {
                if ($null -eq $originalWriteFlag) {
                    Remove-Item Env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_LOGGING_FORCE_LOG_WRITE_ERROR = $originalWriteFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Format-DateTimeLog timestamps when DateTimeFormatting is available' {
            $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
            $dateFormattingPath = Join-Path $libPath 'utilities' 'DateTimeFormatting.psm1'
            if (Test-Path -LiteralPath $dateFormattingPath) {
                Import-Module $dateFormattingPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }

            $logFile = Join-Path $script:TempDir 'formatted-timestamp.log'
            Write-ScriptMessage -Message 'formatted entry' -LogFile $logFile

            $content = Get-Content -LiteralPath $logFile -Raw
            $content | Should -Match 'formatted entry'
        }

        It 'Uses locale formatting when only Locale module helpers are available' {
            $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
            Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
            $localePath = Join-Path $libPath 'core' 'Locale.psm1'
            if (Test-Path -LiteralPath $localePath) {
                Import-Module $localePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }

            $logFile = Join-Path $script:TempDir 'locale-timestamp.log'
            Write-ScriptMessage -Message 'locale entry' -LogFile $logFile

            $content = Get-Content -LiteralPath $logFile -Raw
            $content | Should -Match 'locale entry'
        }

        It 'Rotates multiple archived log files when appending beyond the size limit' {
            $logFile = Join-Path $script:TempDir 'multi-rotate.log'
            $chunk = 'Z' * (600 * 1024)
            Write-ScriptMessage -Message $chunk -LogFile $logFile -AppendLog -MaxLogFileSizeMB 1 -MaxLogFiles 3
            Write-ScriptMessage -Message $chunk -LogFile $logFile -AppendLog -MaxLogFileSizeMB 1 -MaxLogFiles 3
            Write-ScriptMessage -Message 'final-entry' -LogFile $logFile -AppendLog -MaxLogFileSizeMB 1 -MaxLogFiles 3

            Test-Path -LiteralPath $logFile | Should -Be $true
            $archived = Get-ChildItem -Path "$logFile.*" -ErrorAction SilentlyContinue
            if ($archived) {
                @($archived).Count | Should -BeLessOrEqual 3
            }
        }
    }
}
