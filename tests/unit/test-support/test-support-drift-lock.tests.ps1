<#
tests/unit/test-support/test-support-drift-lock.tests.ps1

.SYNOPSIS
    Unit tests for drift.lock test helpers in TestSupport/TestDriftLock.ps1.
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
}

Describe 'TestDriftLock helpers' {
    It 'Test-DriftLockContains matches binding fragments without regex parsing issues' {
        $content = @'
tests/unit/example.tests.ps1 -> profile.d/bootstrap.ps1 sig:be0601c5d62e45fd
'@

        Test-DriftLockContains -DriftLockContent $content -Text 'tests/unit/example.tests.ps1' | Should -BeTrue
        Test-DriftLockContains -DriftLockContent $content -Text 'profile.d/bootstrap.ps1 sig:' | Should -BeTrue
        Test-DriftLockContains -DriftLockContent $content -Text 'tests/missing.tests.ps1' | Should -BeFalse
    }

    It 'Invoke-WithTestDriftLockBackup restores the original drift.lock contents' {
        $driftLockPath = Join-Path $script:TestRepoRoot 'drift.lock'
        if (-not (Test-Path -LiteralPath $driftLockPath)) {
            Set-ItResult -Skipped -Because 'drift.lock is not present'
            return
        }

        $originalLock = Get-Content -LiteralPath $driftLockPath -Raw
        $marker = 'tests/test-artifacts/drift-lock-helper-marker.tests.ps1 -> profile.d/bootstrap.ps1 sig:be0601c5d62e45fd'

        Invoke-WithTestDriftLockBackup {
            param($LockPath)

            Add-Content -LiteralPath $LockPath -Value $marker -Encoding UTF8
            (Get-Content -LiteralPath $LockPath -Raw).Contains($marker) | Should -BeTrue
        }

        $restoredLock = Get-Content -LiteralPath $driftLockPath -Raw
        $restoredLock | Should -BeExactly $originalLock
        (Test-DriftLockContains -DriftLockContent $restoredLock -Text $marker) | Should -BeFalse
    }
}
