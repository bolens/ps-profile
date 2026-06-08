<#
tests/unit/test-runner-spellcheck-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for spellcheck.ps1 cspell delegation workflow.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SpellcheckScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/spellcheck.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'SpellcheckExtended'
    $script:PsExe = (Get-Command pwsh -ErrorAction Stop).Source
}

Describe 'spellcheck.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Paths parameter with default glob' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match '\.PARAMETER Paths'
            $content | Should -Match '\*\*/\*'
        }

        It 'Documents non-blocking behavior when cspell is unavailable' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match 'non-blocking'
            $content | Should -Match 'cspell not found'
        }
    }

    Context 'Exit code handling' {
        It 'Uses Test-CommandAvailable to detect cspell' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match 'Test-CommandAvailable'
            $content | Should -Match "'cspell'"
        }

        It 'Exits successfully when cspell is not on PATH' {
            $isolatedPath = Join-Path $script:TempRoot 'empty-path'
            New-Item -ItemType Directory -Path $isolatedPath -Force | Out-Null

            & $script:PsExe -NoProfile -NonInteractive -Command @"
`$env:PATH = '$isolatedPath'
& '$($script:SpellcheckScript -replace "'", "''")' -Paths '*.md'
exit `$LASTEXITCODE
"@ 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Maps cspell failures to EXIT_VALIDATION_FAILURE' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'cspell found spelling errors'
        }
    }
}
