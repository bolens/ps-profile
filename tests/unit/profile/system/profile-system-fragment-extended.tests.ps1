<#
tests/unit/profile-system-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system.ps1'
}
Describe 'profile.d/system.ps1 extended scenarios' {
    It 'Declares essential tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defers system module loading through Ensure-System' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-System'
        $c | Should -Match 'Load-EnsureModules'
    }
    It 'Documents on-demand loading instead of eager imports at profile startup' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'loaded on-demand'
    }
}
