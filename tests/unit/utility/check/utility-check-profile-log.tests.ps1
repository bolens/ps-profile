<#
tests/unit/utility-check-profile-log.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-profile-log.ps1 log inspection output.
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
    It 'Reports profile loading log status without interactive prompts' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckProfileLogScript

        $result.Output | Should -Match 'Profile Loading Log|Log file'
    }

    It 'Reports when the profile loading log file is missing' {
        $logFile = Join-Path ([IO.Path]::GetTempPath()) 'powershell-profile-load.log'
        $backup = $null
        if (Test-Path -LiteralPath $logFile) {
            $backup = Join-Path (New-TestTempDirectory -Prefix 'ProfileLogBackup') 'powershell-profile-load.log'
            Move-Item -LiteralPath $logFile -Destination $backup -Force
        }

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:CheckProfileLogScript

            $result.Output | Should -Match 'Log file not found|profile may not have started executing'
        }
        finally {
            if ($null -ne $backup -and (Test-Path -LiteralPath $backup)) {
                Move-Item -LiteralPath $backup -Destination $logFile -Force
            }
        }
    }

    It 'Displays recent entries when the profile loading log file exists' {
        $logFile = Join-Path ([IO.Path]::GetTempPath()) 'powershell-profile-load.log'
        $backup = $null
        if (Test-Path -LiteralPath $logFile) {
            $backup = Get-Content -LiteralPath $logFile -Raw
        }

        try {
            @(
                '2026-01-01T00:00:00Z Loaded bootstrap.ps1'
                '2026-01-01T00:00:01Z Loaded env.ps1'
            ) | Set-Content -LiteralPath $logFile -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:CheckProfileLogScript

            $result.Output | Should -Match 'Last 50 log entries'
            $result.Output | Should -Match 'Loaded bootstrap\.ps1'
            $result.Output | Should -Match 'Total log entries: 2'
        }
        finally {
            if ($null -eq $backup) {
                Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
            }
            else {
                Set-Content -LiteralPath $logFile -Value $backup -Encoding UTF8 -NoNewline
            }
        }
    }
}
