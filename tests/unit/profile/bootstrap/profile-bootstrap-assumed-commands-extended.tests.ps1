<#
tests/unit/profile-bootstrap-assumed-commands-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/AssumedCommands.ps1'
}
Describe 'profile.d/bootstrap/AssumedCommands.ps1 extended scenarios' {
    It 'Documents assumed command management utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Assumed command management utilities'
        $c | Should -Match 'treat as present'
    }
    It 'Defines Add-AssumedCommand using AssumedAvailableCommands cache' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Add-AssumedCommand'
        $c | Should -Match 'AssumedAvailableCommands'
        $c | Should -Match 'TryAdd'
    }
    It 'Defines Remove-AssumedCommand and Get-AssumedCommands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Remove-AssumedCommand'
        $c | Should -Match 'Get-AssumedCommands'
    }
}
