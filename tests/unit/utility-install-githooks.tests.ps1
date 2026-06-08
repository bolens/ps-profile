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
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
}
