<#
tests/unit/utility-run-format.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-format.ps1 dry-run execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunFormatScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-format.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-format.ps1 execution' {
    It 'DryRun previews formatting for an isolated scripts directory' {
        $formatDir = Join-Path ([System.IO.Path]::GetTempPath()) ('RunFormatFixture-{0}' -f [System.Guid]::NewGuid())
        New-Item -ItemType Directory -Path $formatDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $formatDir 'sample.ps1') -Value "function Get-RunFormatFixture { 'ok' }" -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:RunFormatScript -ArgumentList @(
                '-Path', $formatDir,
                '-DryRun'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DRY RUN|Dry run|Would format'
        }
        finally {
            if (Test-Path -LiteralPath $formatDir) {
                Remove-Item -LiteralPath $formatDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
