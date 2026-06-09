<#
tests/unit/library-test-coverage-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-TestCoverage parsing edge cases.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'code-analysis' 'TestCoverage.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'TestCoverageExtended'
    $script:AllUncoveredXml = Join-Path $script:TempDir 'all-uncovered.xml'
    $script:InvalidXml = Join-Path $script:TempDir 'invalid.xml'

    @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="C:\test\AllUncovered.psm1">
        <Function FunctionName="Test-AllUncovered">
            <Line Number="1" Covered="false" />
            <Line Number="2" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@ | Set-Content -LiteralPath $script:AllUncoveredXml -Encoding UTF8

    Set-Content -LiteralPath $script:InvalidXml -Value '{ not valid xml' -Encoding UTF8
}

AfterAll {
    Remove-Module TestCoverage -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestCoverage extended scenarios' {
    Context 'Get-TestCoverage' {
        It 'Returns zero percent coverage when no lines are covered' {
            $result = Get-TestCoverage -CoverageXmlPath $script:AllUncoveredXml

            $result.CoveragePercent | Should -Be 0
            $result.CoveredLines | Should -Be 0
            $result.TotalLines | Should -Be 2
        }

        It 'Calculates per-file coverage percentages in FileCoverage entries' {
            $result = Get-TestCoverage -CoverageXmlPath $script:AllUncoveredXml

            @($result.FileCoverage).Count | Should -Be 1
            $result.FileCoverage[0].CoveragePercent | Should -Be 0
            $result.FileCoverage[0].File | Should -Be 'AllUncovered.psm1'
        }

        It 'Returns parse error details for invalid XML files' {
            $result = Get-TestCoverage -CoverageXmlPath $script:InvalidXml -WarningAction SilentlyContinue

            $result.CoveragePercent | Should -Be 0
            $result.PSObject.Properties.Name | Should -Contain 'Error'
        }

        It 'Returns UTC timestamps that parse as DateTime values' {
            $result = Get-TestCoverage -CoverageXmlPath $script:AllUncoveredXml

            { [DateTime]::Parse($result.Timestamp) } | Should -Not -Throw
        }

        It 'Reports zero metrics for missing coverage files without throwing' {
            $missing = Join-Path $script:TempDir 'does-not-exist.xml'

            { Get-TestCoverage -CoverageXmlPath $missing -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Calculates partial coverage for mixed covered and uncovered lines' {
            $mixedXml = Join-Path $script:TempDir 'mixed-coverage.xml'
            @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="/tmp/Mixed.psm1">
        <Function FunctionName="Test-Mixed">
            <Line Number="1" Covered="true" />
            <Line Number="2" Covered="false" />
            <Line Number="3" Covered="true" />
            <Line Number="4" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@ | Set-Content -LiteralPath $mixedXml -Encoding UTF8

            $result = Get-TestCoverage -CoverageXmlPath $mixedXml

            $result.CoveragePercent | Should -Be 50
            $result.CoveredLines | Should -Be 2
            $result.TotalLines | Should -Be 4
            $result.FileCoverage[0].CoveragePercent | Should -Be 50
        }

        It 'Uses plain warnings for missing files when structured logging is disabled' {
            $missing = Join-Path $script:TempDir 'plain-missing.xml'
            $originalFlag = $env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING
            $env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING = '1'

            try {
                $result = Get-TestCoverage -CoverageXmlPath $missing -WarningAction SilentlyContinue
                $result.CoveragePercent | Should -Be 0
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING = $originalFlag
                }
            }
        }

        It 'Uses structured warnings for missing files when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $missing = Join-Path $script:TempDir 'structured-missing.xml'
            $result = Get-TestCoverage -CoverageXmlPath $missing -WarningAction SilentlyContinue
            $result.CoveragePercent | Should -Be 0
        }

        It 'Returns parse error details when forced through the test hook' {
            $originalFlag = $env:PS_PROFILE_TEST_COVERAGE_FORCE_PARSE_ERROR
            $env:PS_PROFILE_TEST_COVERAGE_FORCE_PARSE_ERROR = '1'

            try {
                $result = Get-TestCoverage -CoverageXmlPath $script:AllUncoveredXml -WarningAction SilentlyContinue
                $result.Error | Should -Match 'coverage parse failure probe'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_TEST_COVERAGE_FORCE_PARSE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_TEST_COVERAGE_FORCE_PARSE_ERROR = $originalFlag
                }
            }
        }

        It 'Uses plain warnings for parse failures when structured logging is disabled' {
            $originalFlag = $env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING
            $env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING = '1'

            try {
                $result = Get-TestCoverage -CoverageXmlPath $script:InvalidXml -WarningAction SilentlyContinue
                $result.Error | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_TEST_COVERAGE_DISABLE_STRUCTURED_WARNING = $originalFlag
                }
            }
        }

        It 'Emits structured parse failure warnings with debug level 3' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-TestCoverage -CoverageXmlPath $script:InvalidXml -WarningAction SilentlyContinue
                $result.Error | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-TestCoverage -CoverageXmlPath $script:AllUncoveredXml
                $result.TotalLines | Should -Be 2
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }
}
