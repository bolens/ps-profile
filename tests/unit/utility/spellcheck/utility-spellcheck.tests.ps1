<#
tests/unit/utility-spellcheck.tests.ps1

.SYNOPSIS
    Behavioral unit tests for spellcheck.ps1 execution.
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
    $script:SpellcheckScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'spellcheck.ps1'
    $ConfirmPreference = 'None'
}

Describe 'spellcheck.ps1 execution' {
    It 'Exits successfully and skips when cspell is not installed' {
        if (Get-Command cspell -ErrorAction SilentlyContinue) {
            Set-ItResult -Skipped -Because 'cspell is installed; skip-path test requires cspell to be absent'
            return
        }

        $docPath = Join-Path (New-TestTempDirectory -Prefix 'SpellcheckSkip') 'readme.md'
        Set-Content -LiteralPath $docPath -Value '# Spellcheck skip fixture' -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SpellcheckScript -ArgumentList @(
                '-Paths', $docPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'cspell not found|Skipping local spellcheck'
        }
        finally {
            $parent = Split-Path -Parent $docPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Passes a clean document when cspell is available' {
        if (-not (Get-Command cspell -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'cspell is not installed'
            return
        }

        $docPath = Join-Path (New-TestTempDirectory -Prefix 'SpellcheckClean') 'readme.md'
        Set-Content -LiteralPath $docPath -Value '# Spellcheck clean fixture document' -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SpellcheckScript -ArgumentList @(
                '-Paths', $docPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'cspell passed'
        }
        finally {
            $parent = Split-Path -Parent $docPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails validation when cspell finds a spelling error' {
        if (-not (Get-Command cspell -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'cspell is not installed'
            return
        }

        $docPath = Join-Path (New-TestTempDirectory -Prefix 'SpellcheckTypo') 'readme.md'
        Set-Content -LiteralPath $docPath -Value 'zzqxwtypofixtureword' -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SpellcheckScript -ArgumentList @(
                '-Paths', $docPath
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'cspell found spelling errors'
        }
        finally {
            $parent = Split-Path -Parent $docPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
