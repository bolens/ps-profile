<#
tests/unit/utility-install-githooks.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/git/install-githooks.ps1.
#>

function global:New-InstallGitHooksTestRepository {
    $repo = New-TestTempDirectory -Prefix 'InstallHooksRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    $scriptsGitDir = Join-Path $scriptsDir 'git'
    New-Item -ItemType Directory -Path $scriptsGitDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks') -Destination (Join-Path $scriptsGitDir 'hooks') -Recurse -Force
    Copy-Item -LiteralPath $script:InstallHooksScript -Destination (Join-Path $scriptsGitDir 'install-githooks.ps1') -Force

    Push-Location $repo
    try {
    git init -q | Out-Null
    git config user.email 'fixture@example.com'
    git config user.name 'Fixture'
    }
    finally {
        Pop-Location
    }

    return $repo
}

function global:Invoke-InstallGitHooksScript {
    param(
        [string]$RepositoryRoot,
        [string[]]$ExtraArgs
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'git' 'install-githooks.ps1'
    Push-Location $RepositoryRoot
    try {
    $output = & pwsh -NoProfile -File $scriptPath @ExtraArgs 2>&1 | Out-String
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
        $repo = New-InstallGitHooksTestRepository
        $result = Invoke-InstallGitHooksScript -RepositoryRoot $repo -ExtraArgs @('-DryRun')
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN'
        $result.Output | Should -Match 'commit-msg'
        $result.Output | Should -Match 'pre-push'
        Test-Path -LiteralPath (Join-Path $repo '.git' 'commit-msg') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $repo '.git' 'pre-push') | Should -BeFalse
    }

    It 'Installs hook wrappers into .git for each scripts/git/hooks script' {
        $repo = New-InstallGitHooksTestRepository
        $result = Invoke-InstallGitHooksScript -RepositoryRoot $repo
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Git hooks installed|Installing hook'
                $commitMsgHook = Join-Path $repo '.git' 'commit-msg'
        $prePushHook = Join-Path $repo '.git' 'pre-push'
        Test-Path -LiteralPath $commitMsgHook | Should -BeTrue
        Test-Path -LiteralPath $prePushHook | Should -BeTrue
        Get-Content -LiteralPath $commitMsgHook -Raw | Should -Match 'commit-msg\.ps1'
        Get-Content -LiteralPath $prePushHook -Raw | Should -Match 'pre-push\.ps1'
    }

    It 'Reinstalls hooks idempotently when run a second time' {
        $repo = New-InstallGitHooksTestRepository
        $first = Invoke-InstallGitHooksScript -RepositoryRoot $repo
        $second = Invoke-InstallGitHooksScript -RepositoryRoot $repo
                $first.ExitCode | Should -Be 0
        $second.ExitCode | Should -Be 0
        Test-Path -LiteralPath (Join-Path $repo '.git' 'pre-push') | Should -BeTrue
    }

    It 'Fails when the requested git hooks directory does not exist' {
        $repo = New-TestTempDirectory -Prefix 'InstallHooksMissingGitDir'
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
}
