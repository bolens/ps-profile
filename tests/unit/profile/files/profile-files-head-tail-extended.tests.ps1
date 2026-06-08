<#
tests/unit/profile-files-head-tail-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-modules/inspection/files-head-tail.ps1'
}
Describe 'profile.d/files-modules/inspection/files-head-tail.ps1 extended scenarios' {
    It 'Documents head and tail utilities for file and pipeline input' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File head and tail utility functions'
        $c | Should -Match 'Get first/last N lines'
    }
    It 'Defines Get-FileHead and Get-FileTail with pipeline support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-FileHead'
        $c | Should -Match 'Get-FileTail'
        $c | Should -Match 'Initialize-FileUtilities-HeadTail'
        $c | Should -Match 'Select-Object -First'
    }
    It 'Registers head and tail aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'head'"
        $c | Should -Match "Set-AgentModeAlias -Name 'tail'"
    }
}
