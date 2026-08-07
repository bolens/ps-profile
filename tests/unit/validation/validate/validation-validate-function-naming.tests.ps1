<#
tests/unit/validation/validate/validation-validate-function-naming.tests.ps1

.SYNOPSIS
    Behavioral tests for validate-function-naming.ps1 using isolated fixtures.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ValidateNamingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'validate-function-naming.ps1'
}

Describe 'validate-function-naming.ps1 execution' {
    BeforeEach {
        $script:FixtureRoot = New-TestTempDirectory -Prefix 'FunctionNaming'
        $script:ExceptionsFile = Join-Path $script:FixtureRoot 'exceptions.md'
        Set-Content -LiteralPath $script:ExceptionsFile -Value '# Function naming exceptions' -Encoding UTF8
    }

    It 'accepts approved functions and writes a JSON report' {
        $content = @'
function Get-PortableFixture {
    'ok'
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'approved.ps1') -Value $content -Encoding UTF8
        $reportPath = Join-Path $script:FixtureRoot 'naming-report.json'

        $output = & $script:ValidateNamingScript `
            -Path $script:FixtureRoot `
            -ExceptionsFile $script:ExceptionsFile `
            -OutputPath $reportPath 2>&1 | Out-String

        $output | Should -Match 'validation passed with no issues'
        Test-Path -LiteralPath $reportPath | Should -BeTrue
        (Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json).Summary.TotalFunctions | Should -Be 1
    }

    It 'honors a documented function exception' {
        $content = @'
function Frobnicate-PortableFixture {
    'excepted'
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'excepted.ps1') -Value $content -Encoding UTF8
        Set-Content -LiteralPath $script:ExceptionsFile -Value @'
# Function naming exceptions

- `Frobnicate-PortableFixture`
'@ -Encoding UTF8

        $output = & $script:ValidateNamingScript `
            -Path $script:FixtureRoot `
            -ExceptionsFile $script:ExceptionsFile 2>&1 | Out-String

        $output | Should -Match 'validation passed with no issues'
    }

    It 'can include test paths in strict naming validation' {
        $content = @'
function Frobnicate-PortableFixture {
    'invalid'
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'invalid.ps1') -Value $content -Encoding UTF8

        {
            & $script:ValidateNamingScript `
                -Path $script:FixtureRoot `
                -ExceptionsFile $script:ExceptionsFile `
                -IncludeTests
        } | Should -Throw '*validation failed with 1 issue(s)*'
    }

    It 'handles an empty source directory and missing exceptions file' {
        $missingExceptions = Join-Path $script:FixtureRoot 'missing.md'

        $output = & $script:ValidateNamingScript `
            -Path $script:FixtureRoot `
            -ExceptionsFile $missingExceptions 2>&1 | Out-String

        $output | Should -Match 'validation passed with no issues'
    }

    It 'uses the repository exceptions file when none is specified' {
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'approved.ps1') -Value @'
function Get-DefaultExceptionsFixture {
    'ok'
}
'@ -Encoding UTF8

        $output = & $script:ValidateNamingScript -Path $script:FixtureRoot 2>&1 | Out-String

        $output | Should -Match 'validation passed with no issues'
    }

    It 'uses the repository root when no analysis path is specified' {
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'approved.ps1') -Value @'
function Get-RepositoryRootFixture {
    'ok'
}
'@ -Encoding UTF8

        $output = & $script:ValidateNamingScript `
            -RepositoryRoot $script:FixtureRoot 2>&1 | Out-String

        $output | Should -Match 'validation passed with no issues'
    }
}
