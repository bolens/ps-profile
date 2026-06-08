<#
tests/unit/utility-install-githooks.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/git/install-githooks.ps1.
#>

function global:Invoke-InstallGitHooksScript {
    param(
        [string]$RepositoryRoot,
        [string[]]$ExtraArgs
    )

    Push-Location $RepositoryRoot
    try {
        $output = & pwsh -NoProfile -File $script:InstallHooksScript @ExtraArgs 2>&1 | Out-String
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }
    finally {
        Pop-Location
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
    $script:InstallHooksScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'install-githooks.ps1'
    $ConfirmPreference = 'None'
}

Describe 'install-githooks.ps1 execution' {
    It 'DryRun reports hook installation without writing hook files' {
        $repo = New-TestTempDirectory -Prefix 'InstallHooksRepo'
        try {
            $scriptsDir = Join-Path $repo 'scripts'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks') -Destination (Join-Path $scriptsDir 'git' 'hooks') -Recurse -Force
            New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force | Out-Null

            $result = Invoke-InstallGitHooksScript -RepositoryRoot $repo -ExtraArgs @('-DryRun')
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DRY RUN'
            $result.Output | Should -Match 'commit-msg'
            $result.Output | Should -Match 'pre-push'
            @(Get-ChildItem -Path (Join-Path $repo '.git') -File -ErrorAction SilentlyContinue).Count | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Installs hook wrappers into .git for each scripts/git/hooks script' {
        $repo = New-TestTempDirectory -Prefix 'InstallHooksRepoReal'
        try {
            $scriptsDir = Join-Path $repo 'scripts'
            $scriptsGitDir = Join-Path $scriptsDir 'git'
            $null = New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force
            $null = New-Item -ItemType Directory -Path $scriptsGitDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks') -Destination (Join-Path $scriptsGitDir 'hooks') -Recurse -Force
            Copy-Item -LiteralPath $script:InstallHooksScript -Destination (Join-Path $scriptsGitDir 'install-githooks.ps1') -Force

            $output = & pwsh -NoProfile -File (Join-Path $scriptsGitDir 'install-githooks.ps1') 2>&1 | Out-String
            $result = [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = $output
            }
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Git hooks installed|Installing hook'

            $commitMsgHook = Join-Path $repo '.git' 'commit-msg'
            $prePushHook = Join-Path $repo '.git' 'pre-push'
            Test-Path -LiteralPath $commitMsgHook | Should -BeTrue
            Test-Path -LiteralPath $prePushHook | Should -BeTrue
            Get-Content -LiteralPath $commitMsgHook -Raw | Should -Match 'commit-msg\.ps1'
            Get-Content -LiteralPath $prePushHook -Raw | Should -Match 'pre-push\.ps1'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the requested git hooks directory does not exist' {
        $repo = New-TestTempDirectory -Prefix 'InstallHooksMissingGitDir'
        try {
            $scriptsDir = Join-Path $repo 'scripts'
            $scriptsGitDir = Join-Path $scriptsDir 'git'
            $null = New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force
            $null = New-Item -ItemType Directory -Path $scriptsGitDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks') -Destination (Join-Path $scriptsGitDir 'hooks') -Recurse -Force
            Copy-Item -LiteralPath $script:InstallHooksScript -Destination (Join-Path $scriptsGitDir 'install-githooks.ps1') -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
                git add README.md
                git commit -m 'init' -q
            }
            finally {
                Pop-Location
            }

            $result = Invoke-InstallGitHooksScript -RepositoryRoot $repo -ExtraArgs @('-GitDir', '.git-missing')

            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'Git hooks directory|not found'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
