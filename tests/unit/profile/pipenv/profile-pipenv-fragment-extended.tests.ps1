<#
tests/unit/profile-pipenv-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/pipenv.ps1'
}
Describe 'profile.d/pipenv.ps1 extended scenarios' {
    It 'Declares standard tier guarded by pipenv availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand pipenv\)'
    }
    It 'Defines Install-PipenvPackage with dev dependency flag support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-PipenvPackage'
        $c | Should -Match '\[switch\]\$Dev'
    }
    It 'Registers pipenvinstall and pipenvadd aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pipenvinstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'pipenvadd'"
    }
}
