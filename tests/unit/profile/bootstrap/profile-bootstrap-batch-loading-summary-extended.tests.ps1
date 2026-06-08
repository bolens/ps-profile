<#
tests/unit/profile-bootstrap-batch-loading-summary-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/BatchLoadingSummary.ps1'
}
Describe 'profile.d/bootstrap/BatchLoadingSummary.ps1 extended scenarios' {
    It 'Documents batch loading summary and display utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Batch loading summary and display utilities'
        $c | Should -Match 'BatchLoadingInfo'
    }
    It 'Defines Initialize-BatchLoadingInfo and Record-BatchLoading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-BatchLoadingInfo'
        $c | Should -Match 'Record-BatchLoading'
        $c | Should -Match 'Record-DependencyParsing'
    }
    It 'Defines Show-BatchLoadingSummary and Record-FragmentResults' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Show-BatchLoadingSummary'
        $c | Should -Match 'Record-FragmentResults'
        $c | Should -Match 'Set-TotalFragmentCount'
    }
}
