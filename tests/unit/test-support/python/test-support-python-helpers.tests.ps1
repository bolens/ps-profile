<#
tests/unit/test-support-python-helpers.tests.ps1

.SYNOPSIS
    Unit tests for TestPythonHelpers module.
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
    $script:ProfileDir = Join-Path $script:TestRepoRoot 'profile.d'
}

Describe 'TestPythonHelpers Module' {
    Context 'Get-PythonPackageInstallRecommendation' {
        It 'Prefers uv when available' {
            if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'uv is not available'
                return
            }

            Get-PythonPackageInstallRecommendation -PackageName 'pandas' | Should -Be 'uv pip install pandas'
        }

        It 'Falls back to pip when uv is unavailable' {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'uv is available on this host'
                return
            }

            Get-PythonPackageInstallRecommendation -PackageName 'pandas' | Should -Be 'pip install pandas'
        }

        It 'Honors UseUV switch even when uv is missing' {
            Get-PythonPackageInstallRecommendation -PackageName 'numpy' -UseUV | Should -Be 'uv pip install numpy'
        }
    }

    Context 'Get-ConversionPythonTestContext' {
        It 'Returns python availability metadata' {
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                Set-ItResult -Skipped -Because 'profile.d not found'
                return
            }

            $context = Get-ConversionPythonTestContext -ProfileDir $script:ProfileDir
            $context.ContainsKey('PythonAvailable') | Should -Be $true
            $context.ContainsKey('UVAvailable') | Should -Be $true
            $context.PythonAvailable | Should -BeOfType [bool]
        }

        It 'Includes package availability when requested' {
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                Set-ItResult -Skipped -Because 'profile.d not found'
                return
            }

            $context = Get-ConversionPythonTestContext -ProfileDir $script:ProfileDir -IncludePackageAvailability
            $context.ContainsKey('PandasAvailable') | Should -Be $true
            $context.ContainsKey('PolarsAvailable') | Should -Be $true
            $context.PandasAvailable | Should -BeOfType [bool]
        }
    }

    Context 'Test-PythonPackageAvailable' {
        It 'Returns false for packages that are not installed' {
            if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue) -and -not (Get-Command uv -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'No Python runtime available'
                return
            }

            Test-PythonPackageAvailable -PackageName 'zzz-nonexistent-python-pkg-xyz' | Should -Be $false
        }
    }
}
