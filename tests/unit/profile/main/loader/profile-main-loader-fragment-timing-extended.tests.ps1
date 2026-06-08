<#
tests/unit/profile-main-loader-fragment-timing-extended.tests.ps1
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
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 fragment timing extended scenarios' {
    It 'Documents fragment loading helper timing section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'FRAGMENT LOADING HELPERS'
        $c | Should -Match 'ProfileFragmentTiming.psm1'
        $c | Should -Match 'performance profiling'
    }
    It 'Initializes fragment timing when module is available' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Initialize-FragmentTiming'
        $c | Should -Match 'Import-Module .+profileFragmentTimingModule'
    }
    It 'Warns on timing module load failure when debug enabled' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Failed to load ProfileFragmentTiming module'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
}
