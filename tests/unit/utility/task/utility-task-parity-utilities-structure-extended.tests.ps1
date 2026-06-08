<#
tests/unit/utility-task-parity-utilities-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/modules/TaskParityUtilities.psm1'
}
Describe 'scripts/utils/task-parity/modules/TaskParityUtilities.psm1 structure extended scenarios' {
    It 'Documents cross-platform task-parity helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Cross-platform helpers for task-parity parsing and generation'
        $c | Should -Match 'TaskParityUtilities.psm1'
    }
    It 'Defines encoding and line-ending helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TextLineEnding'
        $c | Should -Match 'Get-TextFileEncoding'
        $c | Should -Match 'Write-TaskParityTextFile'
    }
    It 'Defines VS Code task conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertTo-VsCodeShellTaskDefinition'
        $c | Should -Match 'ConvertFrom-PwshInvocationCommand'
        $c | Should -Match 'Export-ModuleMember'
    }
}
