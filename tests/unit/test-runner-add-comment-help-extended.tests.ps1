<#
tests/unit/test-runner-add-comment-help-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for add-comment-help.ps1 help generation workflow.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CommentHelpScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/add-comment-help.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'AddCommentHelpExtended'
}

Describe 'add-comment-help.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Path DryRun and Force parameters' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match '\.PARAMETER DryRun'
            $content | Should -Match '\.PARAMETER Force'
        }

        It 'Defines New-CommentHelpBlock for AST-based help generation' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match 'function New-CommentHelpBlock'
            $content | Should -Match '\.SYNOPSIS'
        }
    }

    Context 'DryRun execution' {
        It 'Completes dry run without modifying files in a scoped directory' {
            $scanDir = Join-Path $script:TempRoot 'dry-run'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null
            $sampleFile = Join-Path $scanDir 'NeedsHelp.ps1'
            $original = @'
function Get-CommentHelpSample {
    return 42
}
'@
            Set-Content -LiteralPath $sampleFile -Value $original -NoNewline

            & pwsh -NoProfile -NonInteractive -File $script:CommentHelpScript -Path $scanDir -DryRun 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
            (Get-Content -LiteralPath $sampleFile -Raw) | Should -Be $original
        }

        It 'Exits with validation failure when Path does not exist' {
            $missingPath = Join-Path $script:TempRoot 'missing-help-path'

            & pwsh -NoProfile -NonInteractive -File $script:CommentHelpScript -Path $missingPath 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context 'Default scan scope' {
        It 'Scans profile.d scripts and tests when Path is omitted' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match "'profile\.d'"
            $content | Should -Match "'scripts'"
            $content | Should -Match "'tests'"
        }
    }
}
