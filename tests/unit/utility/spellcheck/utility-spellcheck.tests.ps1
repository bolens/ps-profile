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
    $script:PsExe = (Get-Command pwsh -ErrorAction Stop).Source
    $ConfirmPreference = 'None'
}

Describe 'spellcheck.ps1 execution' {
    It 'Uses repo-local cspell when available via node_modules' {
        $cspellEntry = Join-Path $script:TestRepoRoot 'node_modules' 'cspell' 'bin.mjs'
        if (-not (Test-Path -LiteralPath $cspellEntry)) {
            Set-ItResult -Skipped -Because 'node_modules/cspell is not installed'
            return
        }

        # Use /tmp — New-TestTempDirectory lives under tests/ which cspell ignorePaths skips.
        $docPath = Join-Path ([System.IO.Path]::GetTempPath()) ("spellcheck-local-{0}.md" -f [guid]::NewGuid())
        Set-Content -LiteralPath $docPath -Value '# Spellcheck local fixture document' -Encoding utf8NoBOM

        $result = Invoke-TestScriptFile -ScriptPath $script:SpellcheckScript -ArgumentList @(
            '-Paths', $docPath
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'cspell passed|Running cspell'
        Remove-Item -LiteralPath $docPath -Force -ErrorAction SilentlyContinue
    }

    It 'Skips when no cspell runner can be resolved in an empty repository' {
        $orphanRoot = New-TestTempDirectory -Prefix 'SpellcheckOrphan'
        $codeQualityDir = Join-Path $orphanRoot 'scripts' 'utils' 'code-quality'
        New-Item -ItemType Directory -Path $codeQualityDir -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $orphanRoot 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:SpellcheckScript -Destination (Join-Path $codeQualityDir 'spellcheck.ps1') -Force
        Push-Location $orphanRoot
        try { & git init -q 2>$null } finally { Pop-Location }

        $isolatedPath = Join-Path $orphanRoot 'empty-path'
        New-Item -ItemType Directory -Path $isolatedPath -Force | Out-Null
        $orphanScript = Join-Path $codeQualityDir 'spellcheck.ps1'
        $docPath = Join-Path $orphanRoot 'readme.md'
        Set-Content -LiteralPath $docPath -Value '# Spellcheck skip fixture' -Encoding UTF8

        $output = & $script:PsExe -NoProfile -NonInteractive -Command @"
`$env:PATH = '$($isolatedPath -replace "'", "''")'
Remove-Item Env:\PS_PROFILE_REQUIRE_CSPELL -ErrorAction SilentlyContinue
& '$($orphanScript -replace "'", "''")' -Paths '$($docPath -replace "'", "''")'
exit `$LASTEXITCODE
"@ 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 0
        $output | Should -Match 'cspell not found|Skipping local spellcheck'
    }

    It 'Fails validation when cspell finds a spelling error' {
        $localCspell = Join-Path $script:TestRepoRoot 'node_modules' 'cspell' 'bin.mjs'
        if (-not (Test-Path -LiteralPath $localCspell) -and -not (Get-Command cspell -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'cspell is not available'
            return
        }

        $docPath = Join-Path ([System.IO.Path]::GetTempPath()) ("spellcheck-typo-{0}.md" -f [guid]::NewGuid())
        Set-Content -LiteralPath $docPath -Value 'zzqxwtypofixtureword' -Encoding utf8NoBOM

        $raw = & $script:PsExe -NoProfile -NonInteractive -File $script:SpellcheckScript -Paths $docPath 2>&1
        $exitCode = $LASTEXITCODE
        $output = $raw | Out-String
        Remove-Item -LiteralPath $docPath -Force -ErrorAction SilentlyContinue
        $exitCode | Should -Be 1
        $output | Should -Match 'cspell found spelling errors|zzqxwtypofixtureword'
    }
}
