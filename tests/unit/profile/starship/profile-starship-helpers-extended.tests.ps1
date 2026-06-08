<#
tests/unit/profile-starship-helpers-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship/StarshipHelpers.ps1'
}
Describe 'profile.d/starship/StarshipHelpers.ps1 extended scenarios' {
    It 'Documents Starship helper functions for testing and configuration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Starship helper functions'
        $c | Should -Match 'testing and configuration'
    }
    It 'Defines Test-StarshipInitialized and Test-PromptNeedsReplacement' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-StarshipInitialized'
        $c | Should -Match 'Test-PromptNeedsReplacement'
        $c | Should -Match 'Invoke-Starship'
    }
    It 'Defines Get-StarshipPromptArguments for prompt invocation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-StarshipPromptArguments'
        $c | Should -Match 'lastCommandSucceeded'
    }
}
