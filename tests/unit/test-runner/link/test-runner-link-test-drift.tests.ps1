<#
tests/unit/test-runner-link-test-drift.tests.ps1

.SYNOPSIS
    Behavioral unit tests for link-test-drift.ps1 dry-run execution.
#>

function global:Invoke-LinkTestDriftScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:LinkTestDriftScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:LinkTestDriftScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'link-test-drift.ps1'
    $script:DriftCliAvailable = [bool](Get-Command drift -ErrorAction SilentlyContinue)
}

Describe 'link-test-drift.ps1 execution' {
    It 'Fails when the drift CLI is not on PATH' {
        if ($script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is installed'
            return
        }

        $result = Invoke-LinkTestDriftScript -ArgumentList @('-DryRun')
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'drift CLI not found'
    }

    It 'DryRun resolves a library unit test to its module source' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $testPath = Join-Path $script:TestRepoRoot 'tests' 'unit' 'library-cache.tests.ps1'

        $result = Invoke-LinkTestDriftScript -ArgumentList @(
            '-DryRun',
            '-TestPath', $testPath
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Drift test linking summary:'
        $wouldLink = $result.Output -match 'would link:.*library-cache\.tests\.ps1.*Cache\.psm1'
        $skippedExisting = $result.Output -match 'Skipped \(existing\):\s+[1-9]'
        ($wouldLink -or $skippedExisting) | Should -Be $true
    }
}
