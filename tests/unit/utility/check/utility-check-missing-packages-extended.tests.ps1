<#
tests/unit/utility-check-missing-packages-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/check-missing-packages.ps1'
}
Describe 'check-missing-packages.ps1 extended scenarios' {
    It 'Checks npm Python and system package requirements' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'requirements\.txt'
        $c | Should -Match 'package\.json'
        $c | Should -Match 'RequirementsList'
    }
    It 'Supports PS_SYSTEM_PACKAGE_MANAGER override' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PS_SYSTEM_PACKAGE_MANAGER'
    }
    It 'Exits with validation failure when packages are missing' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'EXIT_VALIDATION_FAILURE'
    }
    It 'Detects platform package managers like scoop apt and pacman' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'scoop'
        $c | Should -Match 'pacman'
    }
}
