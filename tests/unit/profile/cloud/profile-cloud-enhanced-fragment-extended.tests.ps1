<#
tests/unit/profile-cloud-enhanced-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/cloud-enhanced.ps1'
}
Describe 'profile.d/cloud-enhanced.ps1 extended scenarios' {
    It 'Declares standard tier and loads modular cloud-modules helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'cloud-modules'
        $c | Should -Match 'cloud-deploy\.ps1'
    }
    It 'Uses Test-FragmentLoaded and Import-FragmentModules for idempotent loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'cloud-enhanced'"
        $c | Should -Match 'Import-FragmentModules'
    }
    It 'Marks fragment loaded after azure gcp and deploy modules are registered' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'cloud-azure\.ps1'
        $c | Should -Match 'cloud-gcp\.ps1'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'cloud-enhanced'"
    }
}
