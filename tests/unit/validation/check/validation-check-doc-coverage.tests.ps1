<#
tests/unit/validation-check-doc-coverage.tests.ps1

.SYNOPSIS
    Behavioral smoke tests for check-doc-coverage.ps1.
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
    $script:CheckDocCoverageScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-doc-coverage.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-doc-coverage.ps1 execution' {
    It 'Emits a JSON coverage report without strict validation failures' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'documentation coverage scan is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript -ArgumentList @('-Json')

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DocumentedFunctionCount|documentation coverage report emitted as JSON'
    }

    It 'Completes in summary mode without requiring -Strict' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'documentation coverage scan is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript

        $result.Output | Should -Match 'Documentation coverage summary|Documented functions'
        $result.ExitCode | Should -BeIn @(0, 1)
    }

    It 'Fails in strict mode when documented functions lack generated markdown files' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageStrict'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
        New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $profilePath '00-fixture.ps1') -Value @'
<#
.SYNOPSIS
    Fixture function for strict documentation coverage tests.
.DESCRIPTION
    Detailed description for fixture.
#>
function Get-DocCoverageStrictFixture {
    'ok'
}
'@ -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript -ArgumentList @(
                '-ProfilePath', $profilePath,
                '-DocsPath', $docsPath,
                '-Strict'
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Missing markdown|blocking issue|Documentation coverage check failed'
        }
        finally {
            if (Test-Path -LiteralPath $fixtureRoot) {
                Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
