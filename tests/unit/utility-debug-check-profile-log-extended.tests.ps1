<#
tests/unit/utility-debug-check-profile-log-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/check-profile-log.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/check-profile-log.ps1'
}
Describe 'check-profile-log.ps1 extended scenarios' {
    It 'Reads powershell-profile-load.log from the temp directory' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'powershell-profile-load\.log'
        $c | Should -Match 'GetTempPath'
    }
    It 'Displays the last 50 log entries when the log exists' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Last 50 log entries'
        $c | Should -Match 'Select-Object -Last 50'
    }
    It 'Explains possible causes when the log file is missing' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Log file not found'
        $c | Should -Match 'syntax error'
    }
}
