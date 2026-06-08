<#
tests/unit/profile-system-archive-operations-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system/ArchiveOperations.ps1'
}
Describe 'profile.d/system/ArchiveOperations.ps1 extended scenarios' {
    It 'Documents archive operation utilities for zip and unzip' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Archive operation utilities'
        $c | Should -Match 'Extracts ZIP archives'
    }
    It 'Defines Expand-ArchiveCustom and Compress-ArchiveCustom wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Expand-ArchiveCustom'
        $c | Should -Match 'Compress-ArchiveCustom'
        $c | Should -Match 'Expand-Archive @args'
    }
    It 'Registers unzip and zip aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'unzip'"
        $c | Should -Match "Set-AgentModeAlias -Name 'zip'"
    }
}
