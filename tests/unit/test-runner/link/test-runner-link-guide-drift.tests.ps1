<#
tests/unit/test-runner-link-guide-drift.tests.ps1

.SYNOPSIS
    Behavioral unit tests for link-guide-drift.ps1 dry-run execution.
#>

function global:Invoke-LinkGuideDriftScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:LinkGuideDriftScript @ArgumentList 2>&1 | Out-String
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
    $script:LinkGuideDriftScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'link-guide-drift.ps1'
    $script:DriftCliAvailable = [bool](Get-Command drift -ErrorAction SilentlyContinue)
}

Describe 'link-guide-drift.ps1 execution' {
    It 'Fails when the drift CLI is not on PATH' {
        if ($script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is installed'
            return
        }

        $result = Invoke-LinkGuideDriftScript -ArgumentList @('-DryRun')
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'drift CLI not found'
    }

    It 'DryRun processes a known guide without failing' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $guidePath = Join-Path $script:TestRepoRoot 'docs' 'guides' 'MODULE_LOADING_STANDARD.md'
        $beforeLock = if (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')) {
            (Get-Item -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')).LastWriteTimeUtc
        }
        else {
            $null
        }

        $result = Invoke-LinkGuideDriftScript -ArgumentList @(
            '-DryRun',
            '-GuidePath', $guidePath
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Drift guide linking summary:'
        $wouldLink = $result.Output -match 'would link:'
        $skippedExisting = $result.Output -match 'Skipped \(existing\):\s+[1-9]'
        ($wouldLink -or $skippedExisting) | Should -Be $true

        if ($null -ne $beforeLock) {
            $afterLock = (Get-Item -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')).LastWriteTimeUtc
            $afterLock | Should -Be $beforeLock
        }
    }
}
