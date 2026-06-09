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

        $testPath = Join-Path $script:TestRepoRoot 'tests' 'unit' 'library' 'cache' 'library-cache.tests.ps1'

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

    It 'Fails when TestPath points to a test file that does not exist' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $missingTest = Join-Path $script:TestRepoRoot 'tests' 'test-artifacts' 'missing-link-drift.tests.ps1'
        $result = Invoke-LinkTestDriftScript -ArgumentList @(
            '-DryRun',
            '-TestPath', $missingTest
        )

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'missing-link-drift|Cannot find path|does not exist'
    }

    It 'DryRun reports unresolved tests when the source target cannot be mapped' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $artifactDir = Join-Path $script:TestRepoRoot 'tests' 'test-artifacts'
        if (-not (Test-Path -LiteralPath $artifactDir)) {
            New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
        }

        $orphanTest = Join-Path $artifactDir 'orphan-link-drift.tests.ps1'
        try {
            Set-Content -LiteralPath $orphanTest -Value @'
Describe 'orphan fixture' {
    It 'Has no resolvable source import' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

            $result = Invoke-LinkTestDriftScript -ArgumentList @(
                '-DryRun',
                '-TestPath', $orphanTest
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Drift test linking summary:'
            $result.Output | Should -Match 'Unresolved:\s+1'
            $result.Output | Should -Match 'orphan-link-drift\.tests\.ps1'
        }
        finally {
            if (Test-Path -LiteralPath $orphanTest) {
                Remove-Item -LiteralPath $orphanTest -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Refresh removes orphaned test bindings for missing test files' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        if (-not (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock'))) {
            Set-ItResult -Skipped -Because 'drift.lock is not present'
            return
        }

        $orphanTestRelative = 'tests/test-artifacts/orphan-drift-cleanup.tests.ps1'
        $orphanBinding = "$orphanTestRelative -> profile.d/bootstrap.ps1 sig:be0601c5d62e45fd"
        $testPath = Join-Path $script:TestRepoRoot 'tests' 'unit' 'library' 'cache' 'library-cache.tests.ps1'

        Invoke-WithTestDriftLockBackup {
            param($DriftLockPath)

            Add-Content -LiteralPath $DriftLockPath -Value $orphanBinding -Encoding UTF8

            $result = Invoke-LinkTestDriftScript -ArgumentList @(
                '-Refresh',
                '-TestPath', $testPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Removed 1 orphaned test binding\(s\)'
            $updatedLock = Get-Content -LiteralPath $DriftLockPath -Raw
            (Test-DriftLockContains -DriftLockContent $updatedLock -Text $orphanTestRelative) | Should -BeFalse
        }
    }

    It 'DryRun leaves orphaned test bindings in drift.lock' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        if (-not (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock'))) {
            Set-ItResult -Skipped -Because 'drift.lock is not present'
            return
        }

        $orphanTestRelative = 'tests/test-artifacts/orphan-drift-dryrun.tests.ps1'
        $orphanBinding = "$orphanTestRelative -> profile.d/bootstrap.ps1 sig:be0601c5d62e45fd"
        $testPath = Join-Path $script:TestRepoRoot 'tests' 'unit' 'library' 'cache' 'library-cache.tests.ps1'

        Invoke-WithTestDriftLockBackup {
            param($DriftLockPath)

            Add-Content -LiteralPath $DriftLockPath -Value $orphanBinding -Encoding UTF8

            $result = Invoke-LinkTestDriftScript -ArgumentList @(
                '-DryRun',
                '-TestPath', $testPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Not -Match 'Removed .* orphaned test binding'
            $updatedLock = Get-Content -LiteralPath $DriftLockPath -Raw
            (Test-DriftLockContains -DriftLockContent $updatedLock -Text $orphanTestRelative) | Should -BeTrue
        }
    }

    It 'Refresh without orphaned bindings does not report orphan removal' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $testPath = Join-Path $script:TestRepoRoot 'tests' 'unit' 'library' 'cache' 'library-cache.tests.ps1'
        $result = Invoke-LinkTestDriftScript -ArgumentList @(
            '-Refresh',
            '-TestPath', $testPath
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Not -Match 'Removed .* orphaned test binding'
    }
}
