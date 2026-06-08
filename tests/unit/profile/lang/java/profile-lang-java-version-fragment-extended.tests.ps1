<#
tests/unit/profile-lang-java-version-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-java-version.ps1'
}
Describe 'profile.d/lang-java-version.ps1 extended scenarios' {
    It 'Declares standard tier for Java version management helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Set-JavaVersion'
    }
    It 'Defines Set-JavaVersion switching JAVA_HOME by version or path' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Set-JavaVersion'
        $c | Should -Match 'JAVA_HOME'
    }
    It 'Uses Test-FragmentLoaded guard and marks fragment loaded on success' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'lang-java-version'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-java-version'"
    }
}
