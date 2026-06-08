<#
tests/unit/utility-generate-dashboard.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-dashboard.ps1 DryRun execution.
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

    It 'Writes an HTML dashboard file when not in DryRun mode' {
        $outputFile = Join-Path (New-TestTempDirectory -Prefix 'DashboardWrite') 'dashboard.html'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDashboardScript -ArgumentList @(
                '-OutputPath', $outputFile
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Dashboard generated successfully'
            Test-Path -LiteralPath $outputFile | Should -BeTrue
            (Get-Content -LiteralPath $outputFile -Raw) | Should -Match '<html|DOCTYPE html'
        }
        finally {
            $parent = Split-Path -Parent $outputFile
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Does not write a dashboard file when nested output directories are missing' {
        $parentDir = New-TestTempDirectory -Prefix 'DashboardNestedMissing'
        $outputFile = Join-Path $parentDir 'nested' 'dashboard.html'
        try {
            Test-Path -LiteralPath (Split-Path -Parent $outputFile) | Should -BeFalse

            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDashboardScript -ArgumentList @(
                '-OutputPath', $outputFile
            )

            $result.ExitCode | Should -BeIn @(0, 2, 3)
            Test-Path -LiteralPath $outputFile | Should -BeFalse
            $result.Output | Should -Match 'Dashboard generated successfully|Could not find a part of the path|Failed to generate dashboard'
        }
        finally {
            if (Test-Path -LiteralPath $parentDir) {
                Remove-Item -LiteralPath $parentDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'DryRun previews historical dashboard generation without writing output' {
        $outputFile = Join-Path (New-TestTempDirectory -Prefix 'DashboardHistoricalDryRun') 'dashboard.html'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDashboardScript -ArgumentList @(
                '-DryRun',
                '-IncludeHistorical',
                '-OutputPath', $outputFile
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DRY RUN|Would generate dashboard|Historical trend analysis'
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
