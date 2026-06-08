<#
tests/unit/profile-lang-java-compilers-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-java-compilers.ps1'
}
Describe 'profile.d/lang-java-compilers.ps1 extended scenarios' {
    It 'Declares standard tier for Kotlin and Scala JVM compilers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Kotlin, Scala'
    }
    It 'Defines Compile-Kotlin and Compile-Scala with missing-tool fallbacks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Compile-Kotlin'
        $c | Should -Match 'Compile-Scala'
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers kotlinc and scalac aliases and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'kotlinc'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-java-compilers'"
    }
}
