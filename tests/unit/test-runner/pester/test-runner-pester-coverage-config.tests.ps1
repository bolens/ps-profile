<#
tests/unit/test-runner-pester-coverage-config.tests.ps1

.SYNOPSIS
    Unit tests for PesterCoverageConfig module edge cases.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterCoverageConfig.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'PesterCoverageConfigTests'
    $script:ProfileDir = Join-Path $script:TempDir 'profile.d/bootstrap'
    $script:TestPath = Join-Path $script:TempDir 'tests/integration/bootstrap/helper-functions.tests.ps1'

    New-Item -ItemType Directory -Path $script:ProfileDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $script:TestPath) -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $script:ProfileDir 'FunctionRegistration.ps1') -Value '# bootstrap helper' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:ProfileDir 'CommandCache.ps1') -Value '# cache helper' -Encoding UTF8
    Set-Content -LiteralPath $script:TestPath -Value "Describe 'Bootstrap helpers' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PesterCoverageConfig Module' {
    Context 'Set-PesterCodeCoverage' {
        It 'Maps known test files to specific source files for targeted coverage' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -Coverage -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir -TestPaths @($script:TestPath)

            $updated.CodeCoverage.Enabled.Value | Should -Be $true
            @($updated.CodeCoverage.Path.Value) | Should -Contain (Join-Path $script:ProfileDir 'FunctionRegistration.ps1')
            @($updated.CodeCoverage.Path.Value) | Should -Contain (Join-Path $script:ProfileDir 'CommandCache.ps1')
        }

        It 'Enables coverage summary mode with default repository output path' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -ShowCoverageSummary -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir

            $updated.CodeCoverage.Enabled.Value | Should -Be $true
            $updated.CodeCoverage.Path.Value | Should -Be $script:ProfileDir
            ($updated.CodeCoverage.OutputPath.Value -replace '\\', '/') | Should -Match 'scripts/data/coverage\.xml$'
        }

        It 'Uses coverage-summary.xml when report path is provided without full coverage' {
            $reportDir = Join-Path $script:TempDir 'reports'
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -ShowCoverageSummary -CoverageReportPath $reportDir -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir

            ($updated.CodeCoverage.OutputPath.Value -replace '\\', '/') | Should -Match 'coverage-summary\.xml$'
        }

        It 'Applies minimum coverage threshold when specified' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -Coverage -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir -MinimumCoverage 85

            $updated.CodeCoverage.CoveragePercentTarget.Value | Should -Be 85
        }
    }
}
