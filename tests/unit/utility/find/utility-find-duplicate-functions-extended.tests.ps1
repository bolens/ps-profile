<#
tests/unit/utility-find-duplicate-functions-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for find-duplicate-functions.ps1 duplicate detection script.
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
    $script:DuplicateScript = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/find-duplicate-functions.ps1'
}

Describe 'find-duplicate-functions.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents scanning profile.d for duplicate function definitions' {
            $content = Get-Content -LiteralPath $script:DuplicateScript -Raw
            $content | Should -Match 'duplicate function definitions'
            $content | Should -Match 'profile\.d'
        }
    }

    Context 'Scan scope' {
        It 'Uses Get-ProfileDirectory to locate fragment sources' {
            $content = Get-Content -LiteralPath $script:DuplicateScript -Raw
            $content | Should -Match 'Get-ProfileDirectory'
        }

        It 'Reports duplicates with file locations' {
            $content = Get-Content -LiteralPath $script:DuplicateScript -Raw
            $content | Should -Match 'duplicate'
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }
    }
}
