<#
tests/unit/test-runner-pester-coverage-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PesterCoverageConfig fallback and output paths.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterCoverageConfig.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'PesterCoverageConfigExtended'
    $script:ProfileDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:ProfileDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $script:ProfileDir 'Sample.ps1') -Value '# sample' -Encoding UTF8

    $script:UnmappedTest = Join-Path $script:TempDir 'tests/unit/custom-unmapped.tests.ps1'
    New-Item -ItemType Directory -Path (Split-Path $script:UnmappedTest) -Force | Out-Null
    Set-Content -LiteralPath $script:UnmappedTest -Value "Describe 'Unmapped' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PesterCoverageConfig extended scenarios' {
    Context 'Set-PesterCodeCoverage' {
        It 'Falls back to ProfileDir when test paths have no source mapping' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -Coverage -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir -TestPaths @($script:UnmappedTest)

            $updated.CodeCoverage.Enabled.Value | Should -Be $true
            $updated.CodeCoverage.Path.Value | Should -Be $script:ProfileDir
        }

        It 'Uses coverage.xml in custom report directories when Coverage is enabled' {
            $reportDir = Join-Path $script:TempDir 'coverage-reports'
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -Coverage -CoverageReportPath $reportDir -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir

            ($updated.CodeCoverage.OutputPath.Value -replace '\\', '/') | Should -Match 'coverage-reports/coverage\.xml$'
        }

        It 'Applies explicit JaCoCo output format when requested' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -Coverage -CodeCoverageOutputFormat 'JaCoCo' -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir

            $updated.CodeCoverage.OutputFormat.Value | Should -Be 'JaCoCo'
        }

        It 'Leaves coverage disabled when neither Coverage nor ShowCoverageSummary is set' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCodeCoverage -Config $config -ProfileDir $script:ProfileDir -RepoRoot $script:TempDir

            $updated.CodeCoverage.Enabled.Value | Should -Be $false
        }
    }
}
