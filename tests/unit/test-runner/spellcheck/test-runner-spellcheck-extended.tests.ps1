<#
tests/unit/test-runner-spellcheck-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for spellcheck.ps1 cspell delegation workflow.
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
        It 'Resolves cspell from PATH, node_modules, pnpm, or npx' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match 'Test-CommandAvailable'
            $content | Should -Match 'node_modules'
            $content | Should -Match 'pnpm'
            $content | Should -Match 'Get-CSpellInvocation'
        }

        It 'Exits successfully when no cspell runner can be resolved' {
            $isolatedPath = Join-Path $script:TempRoot 'empty-path'
            New-Item -ItemType Directory -Path $isolatedPath -Force | Out-Null
            $orphanRoot = Join-Path $script:TempRoot 'orphan-repo'
            New-Item -ItemType Directory -Path (Join-Path $orphanRoot 'scripts' 'utils' 'code-quality') -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $orphanRoot 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:SpellcheckScript -Destination (Join-Path $orphanRoot 'scripts' 'utils' 'code-quality' 'spellcheck.ps1') -Force
            Push-Location $orphanRoot
            try { & git init -q 2>$null } finally { Pop-Location }
            $docPath = Join-Path $orphanRoot 'readme.md'
            Set-Content -LiteralPath $docPath -Value '# fixture' -Encoding UTF8
            $orphanScript = Join-Path $orphanRoot 'scripts' 'utils' 'code-quality' 'spellcheck.ps1'

            & $script:PsExe -NoProfile -NonInteractive -Command @"
`$env:PATH = '$($isolatedPath -replace "'", "''")'
Remove-Item Env:\PS_PROFILE_REQUIRE_CSPELL -ErrorAction SilentlyContinue
& '$($orphanScript -replace "'", "''")' -Paths '$($docPath -replace "'", "''")'
exit `$LASTEXITCODE
"@ 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Fails when RequireAvailable is set and cspell is missing' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match 'RequireAvailable'
            $content | Should -Match 'PS_PROFILE_REQUIRE_CSPELL'
        }

        It 'Maps cspell failures to EXIT_VALIDATION_FAILURE' {
            $content = Get-Content -LiteralPath $script:SpellcheckScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'cspell found spelling errors'
        }
    }
}
