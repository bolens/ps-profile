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
}
