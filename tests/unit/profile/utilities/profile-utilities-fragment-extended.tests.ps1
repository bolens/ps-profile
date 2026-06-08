<#
tests/unit/profile-utilities-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities.ps1'
}
Describe 'profile.d/utilities.ps1 extended scenarios' {
    It 'Declares essential tier with bootstrap and env dependencies' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defers module loading through Ensure-Utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-Utilities'
        $c | Should -Match 'Load-EnsureModules'
    }
    It 'Loads modules from utilities-modules subdirectory' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'utilities-modules'
    }
}
