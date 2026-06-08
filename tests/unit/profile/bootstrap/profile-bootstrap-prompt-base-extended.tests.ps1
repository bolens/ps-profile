<#
tests/unit/profile-bootstrap-prompt-base-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/PromptBase.ps1'
}
Describe 'profile.d/bootstrap/PromptBase.ps1 extended scenarios' {
    It 'Documents base module for prompt framework initialization' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base module for prompt framework initialization'
        $c | Should -Match 'Starship, Oh-My-Posh'
    }
    It 'Defines Initialize-PromptFramework and Test-PromptCommandAvailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-PromptFramework'
        $c | Should -Match 'Test-PromptCommandAvailable'
        $c | Should -Match 'Fallback prompt handling'
    }
    It 'Marks prompt-base fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'prompt-base'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'prompt-base'"
    }
}
