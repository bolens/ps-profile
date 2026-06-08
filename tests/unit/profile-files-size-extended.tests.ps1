<#
tests/unit/profile-files-size-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-modules/inspection/files-size.ps1'
}
Describe 'profile.d/files-modules/inspection/files-size.ps1 extended scenarios' {
    It 'Documents file size utilities with human-readable formatting' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File size utility functions'
        $c | Should -Match 'Get human-readable file sizes'
    }
    It 'Defines Initialize-FileUtilities-Size and Get-FileSize helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileUtilities-Size'
        $c | Should -Match 'Get-FileSize'
        $c | Should -Match 'Ensure-FileUtilities'
        $c | Should -Match '1TB'
    }
    It 'Registers filesize alias targeting Get-FileSize' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'filesize'"
        $c | Should -Match "Target 'Get-FileSize'"
    }
}
