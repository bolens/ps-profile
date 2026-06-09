<#
tests/unit/test-runner/link/test-runner-link-api-drift.tests.ps1

.SYNOPSIS
    Behavioral unit tests for link-api-drift.ps1 dry-run execution.
#>

function global:Invoke-LinkApiDriftScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:LinkApiDriftScript @ArgumentList 2>&1 | Out-String
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
    $script:LinkApiDriftScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'link-api-drift.ps1'
    $script:DriftCliAvailable = [bool](Get-Command drift -ErrorAction SilentlyContinue)
}

Describe 'link-api-drift.ps1 execution' {
    It 'Fails when the drift CLI is not on PATH' {
        if ($script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is installed'
            return
        }

        $result = Invoke-LinkApiDriftScript -ArgumentList @('-DryRun')
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'drift CLI not found'
    }

    It 'DryRun resolves a generated function doc to its profile source' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $docPath = Join-Path $script:TestRepoRoot 'docs' 'api' 'functions' 'Convert-3DFormat.md'
        $beforeLock = if (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')) {
            (Get-Item -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')).LastWriteTimeUtc
        }
        else {
            $null
        }

        $result = Invoke-LinkApiDriftScript -ArgumentList @(
            '-DryRun',
            '-DocPath', $docPath
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Drift API linking summary:'
        $wouldLink = $result.Output -match 'would link:.*Convert-3DFormat\.md.*profile\.d/3d-cad\.ps1'
        $skippedExisting = $result.Output -match 'Skipped \(existing\):\s+[1-9]'
        ($wouldLink -or $skippedExisting) | Should -Be $true

        if ($null -ne $beforeLock) {
            $afterLock = (Get-Item -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')).LastWriteTimeUtc
            $afterLock | Should -Be $beforeLock
        }
    }

    It 'Fails when DocPath points to a markdown file that does not exist' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $missingDoc = Join-Path $script:TestRepoRoot 'docs' 'api' 'functions' 'definitely-not-an-api-doc-xyz.md'
        $result = Invoke-LinkApiDriftScript -ArgumentList @(
            '-DryRun',
            '-DocPath', $missingDoc
        )

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'definitely-not-an-api-doc-xyz|Cannot find path|does not exist'
    }

    It 'DryRun reports unresolved docs when the source line is missing' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $artifactDir = Join-Path $script:TestRepoRoot 'tests' 'test-artifacts'
        if (-not (Test-Path -LiteralPath $artifactDir)) {
            New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
        }

        $orphanDoc = Join-Path $artifactDir 'orphan-api-drift-doc.md'
        try {
            Set-Content -LiteralPath $orphanDoc -Value @'
# Orphan API Doc

## Synopsis

Fixture doc without a source anchor.
'@ -Encoding UTF8

            $result = Invoke-LinkApiDriftScript -ArgumentList @(
                '-DryRun',
                '-DocPath', $orphanDoc
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Drift API linking summary:'
            $result.Output | Should -Match 'Unresolved:\s+1'
            $result.Output | Should -Match 'orphan-api-drift-doc\.md'
        }
        finally {
            if (Test-Path -LiteralPath $orphanDoc) {
                Remove-Item -LiteralPath $orphanDoc -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'DryRun with Refresh reports the linking summary without modifying drift.lock' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $docPath = Join-Path $script:TestRepoRoot 'docs' 'api' 'aliases' 'Git-CurrentBranch.md'
        $beforeLock = if (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')) {
            (Get-Item -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')).LastWriteTimeUtc
        }
        else {
            $null
        }

        $result = Invoke-LinkApiDriftScript -ArgumentList @(
            '-DryRun',
            '-Refresh',
            '-DocPath', $docPath
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Drift API linking summary:'

        if ($null -ne $beforeLock) {
            $afterLock = (Get-Item -LiteralPath (Join-Path $script:TestRepoRoot 'drift.lock')).LastWriteTimeUtc
            $afterLock | Should -Be $beforeLock
        }
    }

    It 'DryRun accepts relative DocPath values' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $result = Invoke-LinkApiDriftScript -ArgumentList @(
            '-DryRun',
            '-DocPath', 'docs/api/aliases/Git-CurrentBranch.md'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Drift API linking summary:'
        $wouldLink = $result.Output -match 'would link:.*Git-CurrentBranch\.md.*profile\.d/git\.ps1'
        $skippedExisting = $result.Output -match 'Skipped \(existing\):\s+[1-9]'
        ($wouldLink -or $skippedExisting) | Should -Be $true
    }

    It 'DryRun reports unresolved docs when the source file does not exist' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $artifactDir = Join-Path $script:TestRepoRoot 'tests' 'test-artifacts'
        if (-not (Test-Path -LiteralPath $artifactDir)) {
            New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
        }

        $brokenSourceDoc = Join-Path $artifactDir 'broken-api-drift-source.md'
        try {
            Set-Content -LiteralPath $brokenSourceDoc -Value @'
# Broken Source Doc

## Source

Defined in: ../profile.d/definitely-not-an-api-source-xyz.ps1
'@ -Encoding UTF8

            $result = Invoke-LinkApiDriftScript -ArgumentList @(
                '-DryRun',
                '-DocPath', $brokenSourceDoc
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Unresolved:\s+1'
            $result.Output | Should -Match 'broken-api-drift-source\.md'
        }
        finally {
            if (Test-Path -LiteralPath $brokenSourceDoc) {
                Remove-Item -LiteralPath $brokenSourceDoc -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'DryRun skips README.md when DocPath is a directory' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $fixtureDir = Join-Path $script:TestRepoRoot 'tests' 'test-artifacts' 'api-drift-doc-dir'
        $fixtureDoc = Join-Path $fixtureDir 'sample-api-doc.md'
        $fixtureReadme = Join-Path $fixtureDir 'README.md'
        New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null

        try {
            Set-Content -LiteralPath $fixtureReadme -Value '# Index' -Encoding UTF8
            Set-Content -LiteralPath $fixtureDoc -Value @'
# Sample API Doc

## Source

Defined in: ../profile.d/bootstrap.ps1
'@ -Encoding UTF8

            $result = Invoke-LinkApiDriftScript -ArgumentList @(
                '-DryRun',
                '-DocPath', $fixtureDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'would link:.*sample-api-doc\.md -> profile\.d/bootstrap\.ps1'
            $result.Output | Should -Not -Match 'README\.md'
        }
        finally {
            Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Refresh links a fixture API doc and updates drift.lock' {
        if (-not $script:DriftCliAvailable) {
            Set-ItResult -Skipped -Because 'drift CLI is not installed'
            return
        }

        $driftLockPath = Join-Path $script:TestRepoRoot 'drift.lock'
        if (-not (Test-Path -LiteralPath $driftLockPath)) {
            Set-ItResult -Skipped -Because 'drift.lock is not present'
            return
        }

        $fixtureDir = Join-Path $script:TestRepoRoot 'tests' 'test-artifacts' 'api-drift-link-fixture'
        $fixtureDoc = Join-Path $fixtureDir 'linkable-api-doc.md'
        $fixtureRelative = 'tests/test-artifacts/api-drift-link-fixture/linkable-api-doc.md'
        New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null

        try {
            Set-Content -LiteralPath $fixtureDoc -Value @'
# Linkable API Doc

## Source

Defined in: ../profile.d/bootstrap.ps1
'@ -Encoding UTF8

            Invoke-WithTestDriftLockBackup {
                param($DriftLockPath)

                $result = Invoke-LinkApiDriftScript -ArgumentList @(
                    '-Refresh',
                    '-DocPath', $fixtureDoc
                )

                $result.ExitCode | Should -Be 0
                $result.Output | Should -Match 'Drift API linking summary:'
                $updatedLock = Get-Content -LiteralPath $DriftLockPath -Raw
                $bindingPrefix = "$fixtureRelative -> profile.d/bootstrap.ps1 sig:"
                (Test-DriftLockContains -DriftLockContent $updatedLock -Text $bindingPrefix) | Should -BeTrue
            }
        }
        finally {
            Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
