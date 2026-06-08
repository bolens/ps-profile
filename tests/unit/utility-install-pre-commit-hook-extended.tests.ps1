<#
tests/unit/utility-install-pre-commit-hook-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for install-pre-commit-hook.ps1 backup integration.
#>

function global:New-TestGitRepoWithHook {
    param(
        [string]$HookContent = '# existing hook'
    )

    $repo = New-TestTempDirectory -Prefix 'InstallHookRepo'
    $gitDir = Join-Path $repo '.git'
    $hooksDir = Join-Path $gitDir 'hooks'
    $scriptsGitDir = Join-Path $repo 'scripts' 'git'

    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsGitDir -Force | Out-Null

    $hookPath = Join-Path $hooksDir 'pre-commit'
    Set-Content -LiteralPath $hookPath -Value $HookContent -NoNewline

    $preCommitScriptSource = Join-Path $script:TestRepoRoot 'scripts' 'git' 'pre-commit.ps1'
    Copy-Item -LiteralPath $preCommitScriptSource -Destination (Join-Path $scriptsGitDir 'pre-commit.ps1') -Force

    return [pscustomobject]@{
        RepoRoot = $repo
        HookPath = $hookPath
    }
}

function global:Invoke-InstallPreCommitHook {
    param(
        [string]$RepoRoot,
        [string[]]$ExtraArgs
    )

    $args = @('-RepoRoot', $RepoRoot) + $ExtraArgs
    & pwsh -NoProfile -File $script:InstallHookScript @args 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
            $fixture = New-TestGitRepoWithHook -HookContent '# hook-to-backup'
            try {
                $exitCode = Invoke-InstallPreCommitHook -RepoRoot $fixture.RepoRoot
                $exitCode | Should -Be 0

                $backups = Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks' -SourcePath $fixture.HookPath
                $backups.Count | Should -BeGreaterOrEqual 1
                Get-Content -LiteralPath $backups[0].BackupPath -Raw | Should -Be '# hook-to-backup'
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
            $fixture = New-TestGitRepoWithHook -HookContent '# restore-target'
            try {
                Invoke-InstallPreCommitHook -RepoRoot $fixture.RepoRoot | Should -Be 0
                Set-Content -LiteralPath $fixture.HookPath -Value '# replaced hook' -NoNewline

                $exitCode = Invoke-InstallPreCommitHook -RepoRoot $fixture.RepoRoot -ExtraArgs @('-Restore', '-Force')
                $exitCode | Should -Be 0
                Get-Content -LiteralPath $fixture.HookPath -Raw | Should -Be '# restore-target'
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Prunes older hook backups while keeping the newest copies' {
            $fixture = New-TestGitRepoWithHook -HookContent '# prune-v1'
            try {
                1..3 | ForEach-Object {
                    Set-Content -LiteralPath $fixture.HookPath -Value "# prune-v$_" -NoNewline
                    Invoke-InstallPreCommitHook -RepoRoot $fixture.RepoRoot | Should -Be 0
                    Start-Sleep -Milliseconds 20
                }

                $exitCode = Invoke-InstallPreCommitHook -RepoRoot $fixture.RepoRoot -ExtraArgs @('-Prune', '-KeepCount', '1')
                $exitCode | Should -Be 0

                $remaining = Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks' -SourcePath $fixture.HookPath
                $remaining.Count | Should -Be 1
            }
            finally {
                if (Test-Path $fixture.RepoRoot) {
                    Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
