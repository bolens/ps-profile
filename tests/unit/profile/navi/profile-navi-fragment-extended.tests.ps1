<#
tests/unit/profile-navi-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/navi.ps1'
}
Describe 'profile.d/navi.ps1 extended scenarios' {
    It 'Declares standard tier guarded by navi availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand navi'
    }
    It 'Aliases cheats to navi interactive cheatsheet browser' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name cheats -Value navi"
        $c | Should -Match 'Invoke-NaviSearch'
    }
    It 'Provides navis alias for Invoke-NaviSearch query mode' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name navis -Value Invoke-NaviSearch"
        $c | Should -Match 'Invoke-NaviBest'
    }
}
