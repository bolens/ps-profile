<#
tests/unit/utility-generate-changelog-cli.tests.ps1

.SYNOPSIS
    Behavioral smoke test for generate-changelog.ps1 when git-cliff is installed.
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
    $script:GenerateChangelogScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-changelog.ps1'
    $script:GitCliffAvailable = [bool](Get-Command git-cliff -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'generate-changelog.ps1 with git-cliff installed' {
    It 'Generates CHANGELOG.md using cliff.toml when git-cliff is available' {
        if (-not $script:GitCliffAvailable) {
            Set-ItResult -Skipped -Because 'git-cliff is not installed'
            return
        }

        if (-not (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'cliff.toml'))) {
            Set-ItResult -Skipped -Because 'cliff.toml is not present in the repository root'
            return
        }

        $outputRel = 'tests/test-data/CHANGELOG-cli-test.md'
        $outputFull = Join-Path $script:TestRepoRoot $outputRel
        try {
            if (Test-Path -LiteralPath $outputFull) {
                Remove-Item -LiteralPath $outputFull -Force -ErrorAction SilentlyContinue
            }

            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateChangelogScript -ArgumentList @(
                '-OutputFile', $outputRel
            )

            $result.ExitCode | Should -Be 0
            Test-Path -LiteralPath $outputFull | Should -BeTrue
            $result.Output | Should -Not -Match 'cliff.toml.*is not found'
        }
        finally {
            if (Test-Path -LiteralPath $outputFull) {
                Remove-Item -LiteralPath $outputFull -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
