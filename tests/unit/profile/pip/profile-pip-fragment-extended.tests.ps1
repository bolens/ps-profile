<#
tests/unit/profile-pip-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/pip.ps1'
}
Describe 'profile.d/pip.ps1 extended scenarios' {
    It 'Declares standard tier guarded by pip availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand pip\)'
    }
    It 'Defines Install-PipPackage and Remove-PipPackage wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-PipPackage'
        $c | Should -Match 'Remove-PipPackage'
    }
    It 'Provides Test-PipOutdated and Update-PipPackages maintenance helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-PipOutdated'
        $c | Should -Match 'Update-PipPackages'
    }
}
