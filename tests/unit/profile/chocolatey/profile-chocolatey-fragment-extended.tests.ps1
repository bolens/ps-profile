<#
tests/unit/profile-chocolatey-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/chocolatey.ps1'
}
Describe 'profile.d/chocolatey.ps1 extended scenarios' {
    It 'Declares standard tier guarded by choco availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand choco\)'
    }
    It 'Defines Install-ChocoPackage with version and source parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-ChocoPackage'
        $c | Should -Match '\[string\]\$Version'
    }
    It 'Registers choinstall and chooutdated aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'choinstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'chooutdated'"
    }
}
