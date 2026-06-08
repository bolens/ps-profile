<#
tests/unit/profile-lang-go-tools-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-go-tools.ps1'
}
Describe 'profile.d/lang-go-tools.ps1 extended scenarios' {
    It 'Declares standard tier depending on lang-go-basic fragment' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env, lang-go-basic'
    }
    It 'Wraps goreleaser and golangci-lint with Invoke-MissingToolWarning fallbacks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'goreleaser'
        $c | Should -Match 'golangci-lint'
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers goreleaser and golangci-lint aliases and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'goreleaser'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-go-tools'"
    }
}
