<#
tests/unit/utility-spellcheck.tests.ps1

.SYNOPSIS
    Behavioral unit tests for spellcheck.ps1 execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SpellcheckScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'spellcheck.ps1'
    $ConfirmPreference = 'None'
}

Describe 'spellcheck.ps1 execution' {
    It 'Completes non-interactively for a narrow path scope' {
        $docPath = Join-Path (New-TestTempDirectory -Prefix 'SpellcheckFixture') 'readme.md'
        Set-Content -LiteralPath $docPath -Value '# Spellcheck fixture document' -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SpellcheckScript -ArgumentList @(
                '-Paths', $docPath
            )

            $result.ExitCode | Should -BeIn @(0, 1, 2)
            if (-not (Get-Command cspell -ErrorAction SilentlyContinue)) {
                $result.Output | Should -Match 'cspell not found|Skipping local spellcheck'
            }
        }
        finally {
            $parent = Split-Path -Parent $docPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
