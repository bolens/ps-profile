<#
tests/unit/profile-re-tools-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/re-tools.ps1'
}
Describe 'profile.d/re-tools.ps1 extended scenarios' {
    It 'Declares optional tier for reverse engineering tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'jadx'
        $c | Should -Match 'ghidra'
    }
    It 'Defines Decompile-Java for Dex and APK analysis workflows' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Decompile-Java'
        $c | Should -Match 'Set-AgentModeFunction'
    }
    It 'Marks re-tools fragment loaded after helper registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 're-tools'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 're-tools'"
    }
}
