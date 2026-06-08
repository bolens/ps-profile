<#
tests/unit/test-runner-test-dependency-management.tests.ps1

.SYNOPSIS
    Unit tests for TestDependencyManagement module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestDependencyManagement.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestDependencyManagement'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestDependencyManagement Module' {
    Context 'Get-TestExecutionOrder' {
        It 'Orders files by suite priority' {
            $unitFile = Join-Path $script:TempDir 'profile-unit-sample.tests.ps1'
            $integrationFile = Join-Path $script:TempDir 'tools-integration-sample.tests.ps1'
            $performanceFile = Join-Path $script:TempDir 'runner-performance-sample.tests.ps1'

            foreach ($file in @($unitFile, $integrationFile, $performanceFile)) {
                Set-Content -LiteralPath $file -Value "Describe 'Sample' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8
            }

            $ordered = @(Get-TestExecutionOrder -TestPaths @($performanceFile, $integrationFile, $unitFile))

            $ordered.IndexOf($unitFile) | Should -BeLessThan $ordered.IndexOf($integrationFile)
            $ordered.IndexOf($integrationFile) | Should -BeLessThan $ordered.IndexOf($performanceFile)
        }

        It 'Parses DependsOn markers from test file comments' {
            $dependentFile = Join-Path $script:TempDir 'dependent.tests.ps1'
            Set-Content -LiteralPath $dependentFile -Value @"
# DependsOn: bootstrap.tests.ps1
Describe 'Dependent' {
    It 'runs' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

            $paths = @(Get-TestExecutionOrder -TestPaths @($dependentFile))
            $paths | Should -Contain $dependentFile
        }
    }
}
