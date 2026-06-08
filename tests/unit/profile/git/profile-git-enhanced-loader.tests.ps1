# ===============================================
# profile-git-enhanced-loader.tests.ps1
# Unit tests for git-enhanced.ps1 modular loader behavior
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    $importCommand = Get-Command Import-FragmentModules -ErrorAction SilentlyContinue
    $global:TestImportFragmentModulesBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

function script:Reset-GitEnhancedLoaderState {
    if ($global:TestImportFragmentModulesBody) {
        Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
    }

    foreach ($fragmentName in @('git-enhanced', 'git-changelog', 'git-gui', 'git-workflow')) {
        Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue
    }

    foreach ($name in @(
            'New-GitChangelog', 'Invoke-GitTower', 'New-GitWorktree',
            'Sync-GitRepos', 'Format-GitCommit'
        )) {
        Remove-Item -Path "Function:\$name" -Force -ErrorAction SilentlyContinue
    }
}

Describe 'git-enhanced.ps1 - fallback module loader' {
    BeforeEach {
        Reset-GitEnhancedLoaderState
    }

    It 'Loads enhanced git modules when Import-FragmentModules is unavailable' {
        Remove-Item -Path Function:\Import-FragmentModules -Force -ErrorAction SilentlyContinue
        Get-Command Import-FragmentModules -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

        try {
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')

            Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command New-GitWorktree -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command Sync-GitRepos -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true
        }
        finally {
            if ($global:TestImportFragmentModulesBody) {
                Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
            }
        }
    }

    It 'Warns about missing modules in fallback mode when PS_PROFILE_DEBUG is set' {
        $changelogPath = Join-Path $script:ProfileDir 'git-modules' 'enhanced' 'git-changelog.ps1'
        $backupPath = "$changelogPath.loader-test.bak"
        $previousDebug = $env:PS_PROFILE_DEBUG

        Remove-Item -Path Function:\Import-FragmentModules -Force -ErrorAction SilentlyContinue

        try {
            if (Test-Path -LiteralPath $backupPath) {
                Remove-Item -LiteralPath $backupPath -Force
            }
            Move-Item -LiteralPath $changelogPath -Destination $backupPath -Force
            $env:PS_PROFILE_DEBUG = '1'

            $output = $(
                . (Join-Path $script:ProfileDir 'git-enhanced.ps1') 3>&1 2>&1
            ) | Out-String

            $output | Should -Match 'git-enhanced: module not found'
            Get-Command New-GitWorktree -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }
        finally {
            if (Test-Path -LiteralPath $backupPath) {
                Move-Item -LiteralPath $backupPath -Destination $changelogPath -Force
            }
            if ($global:TestImportFragmentModulesBody) {
                Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
            }
            if ($null -eq $previousDebug) {
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }
    }

    It 'Uses Import-FragmentModules when the bootstrap helper is available' {
        $global:TestImportFragmentModulesBody | Should -Not -BeNullOrEmpty
        if ($global:TestImportFragmentModulesBody) {
            Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
        }

        Get-Command Import-FragmentModules -ErrorAction Stop | Should -Not -BeNullOrEmpty

        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')

        Get-Command Format-GitCommit -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true
    }
}

Describe 'git-enhanced.ps1 - loader error handling' {
    BeforeEach {
        Reset-GitEnhancedLoaderState
    }

    It 'Reports module load failures through Write-ProfileError when available' {
        $workflowPath = Join-Path $script:ProfileDir 'git-modules' 'enhanced' 'git-workflow.ps1'
        $originalBytes = Backup-TestFileBytes -Path $workflowPath
        $capturedProfileErrors = [System.Collections.Generic.List[object]]::new()

        Remove-Item -Path Function:\Import-FragmentModules -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:\Write-ProfileError -Value {
            param(
                $ErrorRecord,
                $Context,
                $Category
            )

            $capturedProfileErrors.Add($ErrorRecord) | Out-Null
        }.GetNewClosure() -Force

        try {
            Write-TestFileLiteralContent -Path $workflowPath -Content 'throw "loader failure"'

            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
            $capturedProfileErrors.Count | Should -BeGreaterThan 0
            $capturedProfileErrors[0].Exception.Message | Should -Be 'loader failure'
        }
        finally {
            Restore-TestFileBytes -Path $workflowPath -Bytes $originalBytes
            Remove-Item -Path Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
            if ($global:TestImportFragmentModulesBody) {
                Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
            }
        }
    }

    It 'Falls back to Write-Warning when Write-ProfileError is unavailable' {
        $profileError = Get-Command Write-ProfileError -ErrorAction SilentlyContinue
        $profileErrorBody = if ($profileError) { $profileError.ScriptBlock } else { $null }
        $workflowPath = Join-Path $script:ProfileDir 'git-modules' 'enhanced' 'git-workflow.ps1'
        $originalBytes = Backup-TestFileBytes -Path $workflowPath

        Remove-Item -Path Function:\Import-FragmentModules -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue

        try {
            Write-TestFileLiteralContent -Path $workflowPath -Content 'throw "loader failure"'

            $output = $(
                . (Join-Path $script:ProfileDir 'git-enhanced.ps1') 3>&1 2>&1
            ) | Out-String

            $output | Should -Match 'Failed to load git-enhanced fragment'
            $output | Should -Match 'loader failure'
        }
        finally {
            Restore-TestFileBytes -Path $workflowPath -Bytes $originalBytes
            if ($profileErrorBody) {
                Set-Item -Path Function:\Write-ProfileError -Value $profileErrorBody -Force
            }
            else {
                Remove-Item -Path Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
            }
            if ($global:TestImportFragmentModulesBody) {
                Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
            }
        }
    }
}

Describe 'git-enhanced.ps1 - fragment idempotency' {
    BeforeEach {
        Reset-GitEnhancedLoaderState
    }

    It 'Skips re-initialization when git-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true

        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
