<#
tests/unit/profile-lang-go-basic-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-go-basic.ps1'
}
Describe 'profile.d/lang-go-basic.ps1 extended scenarios' {
    It 'Declares standard tier with Test-FragmentLoaded idempotency guard' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match "FragmentName 'lang-go-basic'"
    }
    It 'Defines Invoke-GoRun with go-run alias registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-GoRun'
        $c | Should -Match "Set-AgentModeAlias -Name 'go-run'"
    }
    It 'Documents PowerShell.Profile.Go and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PowerShell.Profile.Go'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-go-basic'"
    }
}
