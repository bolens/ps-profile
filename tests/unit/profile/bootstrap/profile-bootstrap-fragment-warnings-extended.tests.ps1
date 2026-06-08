<#
tests/unit/profile-bootstrap-fragment-warnings-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/FragmentWarnings.ps1'
}
Describe 'profile.d/bootstrap/FragmentWarnings.ps1 extended scenarios' {
    It 'Documents fragment warning suppression utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Fragment warning suppression utilities'
        $c | Should -Match 'PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS'
    }
    It 'Defines Initialize-FragmentWarningSuppression with pattern set' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FragmentWarningSuppression'
        $c | Should -Match 'FragmentWarningPatternSet'
        $c | Should -Match 'SuppressAllFragmentWarnings'
    }
    It 'Defines Test-FragmentWarningSuppressed for per-fragment checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-FragmentWarningSuppressed'
        $c | Should -Match 'FragmentName'
    }
}
