<#
tests/unit/utility-debug-check-profile-log.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-profile-log.ps1 with fixture log files.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckProfileLogScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'check-profile-log.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-profile-log.ps1 execution' {
    It 'Reports when the profile loading log file is missing' {
        $tempDir = New-TestTempDirectory -Prefix 'profile-log-missing'
        try {
            $logPath = Join-Path $tempDir 'powershell-profile-load.log'
            if (Test-Path -LiteralPath $logPath) {
                Remove-Item -LiteralPath $logPath -Force
            }

            $result = Invoke-TestScriptFile -ScriptPath $script:CheckProfileLogScript -EnvironmentVariables @{
                TMPDIR = $tempDir
                TEMP   = $tempDir
                TMP    = $tempDir
            }

            $result.Output | Should -Match 'Profile Loading Log'
            $result.Output | Should -Match 'Log file not found|profile may not have started'
        }
        finally {
            if (Test-Path -LiteralPath $tempDir) {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Displays recent entries when the profile loading log exists' {
        $tempDir = New-TestTempDirectory -Prefix 'profile-log-present'
        try {
            $logPath = Join-Path $tempDir 'powershell-profile-load.log'
            @(
                'fragment bootstrap start'
                'fragment env loaded'
                'fragment git loaded'
            ) | Set-Content -LiteralPath $logPath -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:CheckProfileLogScript -EnvironmentVariables @{
                TMPDIR = $tempDir
                TEMP   = $tempDir
                TMP    = $tempDir
            }

            $result.Output | Should -Match 'Last 50 log entries'
            $result.Output | Should -Match 'fragment git loaded'
            $result.Output | Should -Match 'Total log entries:\s*3'
        }
        finally {
            if (Test-Path -LiteralPath $tempDir) {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
