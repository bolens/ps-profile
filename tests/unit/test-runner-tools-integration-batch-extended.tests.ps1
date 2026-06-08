<#
tests/unit/test-runner-tools-integration-batch-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-tools-integration-batch.ps1 wrapper behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ToolsBatchScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-tools-integration-batch.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'ToolsBatchExtended'
}

Describe 'run-tools-integration-batch.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents RelativePath and SingleSession parameters' {
            $content = Get-Content -LiteralPath $script:ToolsBatchScript -Raw
            $content | Should -Match '\.PARAMETER RelativePath'
            $content | Should -Match '\.PARAMETER SingleSession'
        }

        It 'Documents per-file isolation mode in the description' {
            $content = Get-Content -LiteralPath $script:ToolsBatchScript -Raw
            $content | Should -Match 'per-file'
        }
    }

    Context 'Failure handling' {
        It 'Exits with code 2 when the tools test directory is missing' {
            $fakeRoot = Join-Path $script:TempRoot 'missing-tools-dir'
            New-Item -ItemType Directory -Path $fakeRoot -Force | Out-Null

            & pwsh -NoProfile -NonInteractive -File $script:ToolsBatchScript -RepoRoot $fakeRoot 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with code 2 when RelativePath points to a missing subdirectory' {
            & pwsh -NoProfile -NonInteractive -File $script:ToolsBatchScript -RelativePath 'zzz-nonexistent-subdir' 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Invokes child runners with -NonInteractive in per-file mode' {
            $content = Get-Content -LiteralPath $script:ToolsBatchScript -Raw
            $content | Should -Match '-NonInteractive'
        }
    }

    Context 'Get-PesterRunStats parsing' {
        It 'Defines Get-PesterRunStats with XML fallback support' {
            $content = Get-Content -LiteralPath $script:ToolsBatchScript -Raw
            $content | Should -Match 'function Get-PesterRunStats'
            $content | Should -Match 'ResultXmlPath'
        }
    }
}
