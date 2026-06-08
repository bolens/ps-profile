<#
tests/unit/test-runner-test-dependency-management-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-TestExecutionOrder dependency parsing.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestDependencyManagement.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestDependencyManagementExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestDependencyManagement extended scenarios' {
    Context 'Get-TestExecutionOrder' {
        It 'Returns an empty array when no paths are supplied' {
            @(Get-TestExecutionOrder -TestPaths @()) | Should -Be @()
        }

        It 'Includes missing paths without throwing' {
            $missingPath = Join-Path $script:TempDir 'missing-dependency-target.tests.ps1'

            $ordered = @(Get-TestExecutionOrder -TestPaths @($missingPath))

            $ordered | Should -Contain $missingPath
        }

        It 'Parses multiple DependsOn markers from a test file' {
            $dependentFile = Join-Path $script:TempDir 'multi-dependency.tests.ps1'
            Set-Content -LiteralPath $dependentFile -Value @"
# DependsOn: bootstrap.tests.ps1
# DependsOn: env.tests.ps1
Describe 'Dependent' {
    It 'runs' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

            $ordered = @(Get-TestExecutionOrder -TestPaths @($dependentFile))

            $ordered | Should -Contain $dependentFile
        }

        It 'Treats files without suite keywords as lowest priority' {
            $genericFile = Join-Path $script:TempDir 'generic-sample.tests.ps1'
            $unitFile = Join-Path $script:TempDir 'profile-unit-sample.tests.ps1'

            Set-Content -LiteralPath $genericFile -Value "Describe 'Generic' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8
            Set-Content -LiteralPath $unitFile -Value "Describe 'Unit' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8

            $ordered = @(Get-TestExecutionOrder -TestPaths @($genericFile, $unitFile))

            $ordered.IndexOf($genericFile) | Should -BeLessThan $ordered.IndexOf($unitFile)
        }
    }
}
