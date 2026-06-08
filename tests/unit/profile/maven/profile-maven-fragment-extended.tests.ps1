<#
tests/unit/profile-maven-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/maven.ps1'
}
Describe 'profile.d/maven.ps1 extended scenarios' {
    It 'Declares standard tier guarded by mvn availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand mvn'
    }
    It 'Defines Test-MavenOutdated using versions-maven-plugin display updates' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-MavenOutdated'
        $c | Should -Match 'versions:display-dependency-updates'
    }
    It 'Registers maven-outdated and maven-add aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'maven-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'maven-add'"
    }
}
