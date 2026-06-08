<#
tests/unit/utility-validate-dependencies-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for validate-dependencies.ps1 dependency checker.
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
    $script:ValidateDepsScript = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/validate-dependencies.ps1'
}

Describe 'validate-dependencies.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents InstallMissing and RequirementsFile parameters' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match '\.PARAMETER InstallMissing'
            $content | Should -Match '\.PARAMETER RequirementsFile'
        }

        It 'Documents standard exit codes for validation and setup errors' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'EXIT_SUCCESS'
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'EXIT_SETUP_ERROR'
        }
    }

    Context 'Requirements loading' {
        It 'Uses RequirementsLoader for modular requirements configuration' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'RequirementsLoader'
            $content | Should -Match 'load-requirements\.ps1'
        }

        It 'Validates PowerShell modules and external tools' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'Test-CommandAvailable'
            $content | Should -Match 'Ensure-ModuleAvailable'
        }
    }

    Context 'InstallMissing support' {
        It 'Attempts automatic module installation when requested' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'InstallMissing'
            $content | Should -Match 'automatically install missing'
        }
    }
}
