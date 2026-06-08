<#
tests/unit/utility-generate-dashboard.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-dashboard.ps1 DryRun execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:GenerateDashboardScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'generate-dashboard.ps1'
    $ConfirmPreference = 'None'
}

Describe 'generate-dashboard.ps1 execution' {
    It 'DryRun previews dashboard generation without writing HTML output' {
        $outputFile = Join-Path (New-TestTempDirectory -Prefix 'DashboardDryRun') 'dashboard.html'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDashboardScript -ArgumentList @(
                '-DryRun',
                '-OutputPath', $outputFile
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DRY RUN|Would generate dashboard'
            Test-Path -LiteralPath $outputFile | Should -BeFalse
        }
        finally {
            $parent = Split-Path -Parent $outputFile
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
