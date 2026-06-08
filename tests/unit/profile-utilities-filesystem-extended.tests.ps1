<#
tests/unit/profile-utilities-filesystem-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/filesystem/utilities-filesystem.ps1'
}
Describe 'profile.d/utilities-modules/filesystem/utilities-filesystem.ps1 extended scenarios' {
    It 'Documents file system utilities for file manager integration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File system utility functions'
        $c | Should -Match 'File Explorer integration'
    }
    It 'Defines Open-Explorer with cross-platform file manager launchers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Open-Explorer'
        $c | Should -Match 'explorer.exe'
        $c | Should -Match "Test-CachedCommand 'xdg-open'"
        $c | Should -Match 'nautilus'
    }
    It 'Registers open-explorer alias targeting Open-Explorer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'open-explorer'"
        $c | Should -Match "Target 'Open-Explorer'"
    }
}
