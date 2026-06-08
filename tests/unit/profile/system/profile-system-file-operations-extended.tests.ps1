<#
tests/unit/profile-system-file-operations-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system/FileOperations.ps1'
}
Describe 'profile.d/system/FileOperations.ps1 extended scenarios' {
    It 'Documents file and directory operation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File and directory operation utilities'
        $c | Should -Match 'Unix touch behavior'
    }
    It 'Defines New-EmptyFile and New-Directory with touch semantics' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-EmptyFile'
        $c | Should -Match 'New-Directory'
        $c | Should -Match 'Find-File'
    }
    It 'Registers touch, mkdir, and search aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'touch'"
        $c | Should -Match "Set-AgentModeAlias -Name 'mkdir'"
        $c | Should -Match "Set-AgentModeAlias -Name 'search'"
    }
}
