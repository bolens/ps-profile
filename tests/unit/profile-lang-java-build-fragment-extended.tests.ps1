<#
tests/unit/profile-lang-java-build-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-java-build.ps1'
}
Describe 'profile.d/lang-java-build.ps1 extended scenarios' {
    It 'Declares standard tier for Maven Gradle and Ant build tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Maven, Gradle, Ant'
    }
    It 'Defines Build-Maven and Build-Gradle wrapper functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Build-Maven'
        $c | Should -Match 'Build-Gradle'
    }
    It 'Registers mvn and gradle aliases and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'mvn'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-java-build'"
    }
}
