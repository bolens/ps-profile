<#
tests/unit/profile-files-hash-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-modules/inspection/files-hash.ps1'
}
Describe 'profile.d/files-modules/inspection/files-hash.ps1 extended scenarios' {
    It 'Documents file hash utilities for cryptographic checksums' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File hash utility functions'
        $c | Should -Match 'Calculate cryptographic hashes of files'
    }
    It 'Defines Initialize-FileUtilities-Hash and Get-FileHashValue with SHA256 default' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileUtilities-Hash'
        $c | Should -Match 'Get-FileHashValue'
        $c | Should -Match 'SHA256'
        $c | Should -Match 'Ensure-FileUtilities'
    }
    It 'Registers file-hash alias targeting Get-FileHashValue' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'file-hash'"
        $c | Should -Match "Target 'Get-FileHashValue'"
    }
}
