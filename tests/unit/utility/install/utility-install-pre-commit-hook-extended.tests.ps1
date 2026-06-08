<#
tests/unit/utility-install-pre-commit-hook-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for install-pre-commit-hook.ps1 backup integration.
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
    $script:InstallHookScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'install-pre-commit-hook.ps1'
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop
    $ConfirmPreference = 'None'
}

Describe 'install-pre-commit-hook.ps1 extended scenarios' {
    Context 'Backup integration' {
        It 'Documents restore, prune, and FileBackup usage' {
            $content = Get-Content -LiteralPath $script:InstallHookScript -Raw
            $content | Should -Match '\.PARAMETER Restore'
            $content | Should -Match '\.PARAMETER Prune'
            $content | Should -Match 'FileBackup'
            $content | Should -Match 'git-hooks'
        }

        It 'Stores existing hook backups under .backups/git-hooks before installing' {
            $fixture = New-TestGitRepositoryWithHook -HookContent '# hook-to-backup'
            try {
                $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $fixture.RepoRoot)
                $result.ExitCode | Should -Be 0

                $backups = @(Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks' -SourcePath $fixture.HookPath)
                $backups.Count | Should -BeGreaterOrEqual 1
                Get-Content -LiteralPath $backups[0].BackupPath -Raw | Should -Be '# hook-to-backup'
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Does not write timestamped .bak files beside the hook' {
            $fixture = New-TestGitRepositoryWithHook -HookContent '# no-sidecar-bak'
            try {
                Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $fixture.RepoRoot) |
                    Select-Object -ExpandProperty ExitCode | Should -Be 0

                $sidecarBackups = Get-ChildItem -LiteralPath (Split-Path -Parent $fixture.HookPath) -Filter 'pre-commit.*.bak' -File -ErrorAction SilentlyContinue
                $sidecarBackups | Should -BeNullOrEmpty
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Auto-prunes older hook backups during install when KeepCount is reached' {
            $fixture = New-TestGitRepositoryWithHook -HookContent '# keep-one'
            try {
                1..3 | ForEach-Object {
                    Set-Content -LiteralPath $fixture.HookPath -Value "# hook-$_" -NoNewline
                    Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @(
                        '-RepoRoot', $fixture.RepoRoot,
                        '-KeepCount', '1'
                    ) | Select-Object -ExpandProperty ExitCode | Should -Be 0
                    Start-Sleep -Milliseconds 20
                }

                @(Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks' -SourcePath $fixture.HookPath).Count | Should -Be 1
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Restore and prune actions' {
        It 'Restores the latest backed-up hook content' {
            $fixture = New-TestGitRepositoryWithHook -HookContent '# restore-target'
            try {
                Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $fixture.RepoRoot) |
                    Select-Object -ExpandProperty ExitCode | Should -Be 0
                Set-Content -LiteralPath $fixture.HookPath -Value '# replaced hook' -NoNewline

                $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @(
                    '-RepoRoot', $fixture.RepoRoot,
                    '-Restore',
                    '-Force'
                )
                $result.ExitCode | Should -Be 0
                Get-Content -LiteralPath $fixture.HookPath -Raw | Should -Be '# restore-target'
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Prunes older hook backups while keeping the newest copies' {
            $fixture = New-TestGitRepositoryWithHook -HookContent '# prune-v1'
            try {
                1..3 | ForEach-Object {
                    Set-Content -LiteralPath $fixture.HookPath -Value "# prune-v$_" -NoNewline
                    Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $fixture.RepoRoot) |
                        Select-Object -ExpandProperty ExitCode | Should -Be 0
                    Start-Sleep -Milliseconds 20
                }

                $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @(
                    '-RepoRoot', $fixture.RepoRoot,
                    '-Prune',
                    '-KeepCount', '1'
                )
                $result.ExitCode | Should -Be 0

                @(Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks' -SourcePath $fixture.HookPath).Count | Should -Be 1
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Returns a runtime error when restoring without any stored backups' {
            $fixture = New-TestGitRepositoryWithHook -HookContent '# no-backup-yet'
            try {
                $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @(
                    '-RepoRoot', $fixture.RepoRoot,
                    '-Restore',
                    '-Force'
                )
                $result.ExitCode | Should -Be 3
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
