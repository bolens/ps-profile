#
# Logging helper tests that validate Write-ScriptMessage behavior.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
    $script:LogTestRoot = New-TestTempDirectory -Prefix 'LoggingTests'
}

AfterAll {
    if (Test-Path $script:LogTestRoot) {
        Remove-Item -Path $script:LogTestRoot -Recurse -Force
    }
}

Describe 'Logging Functions' {
    Context 'Write-ScriptMessage with LogFile' {
        BeforeEach {
            $script:TestLogFile = Join-Path $script:LogTestRoot ('log-' + [System.Guid]::NewGuid().ToString() + '.log')
        }

        It 'Writes to log file when LogFile specified' {
            Write-ScriptMessage -Message 'Test log entry' -LogFile $script:TestLogFile
            Test-Path $script:TestLogFile | Should -Be $true
            $content = Get-Content -Path $script:TestLogFile -Raw
            $content | Should -Match 'Test log entry'
        }

        It 'Appends to log file with AppendLog' {
            Write-ScriptMessage -Message 'First entry' -LogFile $script:TestLogFile
            Write-ScriptMessage -Message 'Second entry' -LogFile $script:TestLogFile -AppendLog
            $content = Get-Content -Path $script:TestLogFile
            $content.Count | Should -BeGreaterOrEqual 2
        }

        It 'Creates log directory if needed' {
            $logDir = Join-Path $script:LogTestRoot ([System.Guid]::NewGuid().ToString())
            $logFile = Join-Path $logDir 'test.log'
            Write-ScriptMessage -Message 'Test' -LogFile $logFile
            Test-Path $logDir | Should -Be $true
        }
    }
}