<#
tests/unit/profile-rclone-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/rclone.ps1'
}
Describe 'profile.d/rclone.ps1 extended scenarios' {
    It 'Declares essential tier for rclone remote sync helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'PowerShell.Profile.Rclone'
    }
    It 'Defines Copy-RcloneFile for remote and local path transfers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Copy-RcloneFile'
        $c | Should -Match 'rclone copy'
    }
    It 'Registers rcopy and rls shorthand aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'rcopy'"
        $c | Should -Match "Set-AgentModeAlias -Name 'rls'"
    }
}
