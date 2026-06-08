<#
tests/unit/library-logging-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Write-ScriptMessage structured logging and log files.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
    }
}
