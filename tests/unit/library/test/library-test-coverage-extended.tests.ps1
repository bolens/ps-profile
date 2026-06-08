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
    }
}
