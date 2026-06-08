<#
tests/unit/utility-save-metrics-snapshot.tests.ps1

.SYNOPSIS
    Behavioral unit tests for save-metrics-snapshot.ps1 with an isolated output directory.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SaveSnapshotScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'save-metrics-snapshot.ps1'
    $ConfirmPreference = 'None'
}

Describe 'save-metrics-snapshot.ps1 execution' {
    It 'Writes a metrics snapshot JSON file to an isolated output directory' {
        $outputDir = New-TestTempDirectory -Prefix 'MetricsSnapshot'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SaveSnapshotScript -ArgumentList @(
                '-OutputPath', $outputDir,
                '-IncludeCodeMetrics:False'
            )

            $result.ExitCode | Should -Be 0
            @(Get-ChildItem -LiteralPath $outputDir -Filter '*.json' -ErrorAction SilentlyContinue).Count |
                Should -BeGreaterThan 0
        }
        finally {
            if (Test-Path -LiteralPath $outputDir) {
                Remove-Item -LiteralPath $outputDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
