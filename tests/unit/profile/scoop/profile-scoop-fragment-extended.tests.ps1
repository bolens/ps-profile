<#
tests/unit/profile-scoop-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/scoop.ps1'
}
Describe 'profile.d/scoop.ps1 extended scenarios' {
    It 'Declares essential tier with optional tab completion via PS_SCOOP_ENABLE_COMPLETION' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'PS_SCOOP_ENABLE_COMPLETION'
    }
    It 'Defines Install-ScoopPackage and Find-ScoopPackage helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-ScoopPackage'
        $c | Should -Match 'Find-ScoopPackage'
    }
    It 'Registers sinstall and ss shorthand aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'sinstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ss'"
    }
}
