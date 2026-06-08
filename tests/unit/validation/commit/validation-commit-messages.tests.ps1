<#
tests/unit/validation-commit-messages.tests.ps1

.SYNOPSIS
    Behavioral smoke tests for check-commit-messages.ps1 in an isolated git repository.
#>

function global:New-CommitMessagesSmokeRepository {
    $repo = New-TestTempDirectory -Prefix 'CommitMessagesSmoke'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:CommitMessagesScript -Destination (Join-Path $checksDir 'check-commit-messages.ps1') -Force

    Push-Location $repo
    try {
        & git init -q 2>$null
        & git config user.email 'test@example.com' 2>$null
        & git config user.name 'Test User' 2>$null
        & git commit --allow-empty -m 'feat(init): seed repository' -q 2>$null
    }
    finally {
        Pop-Location
    }

    return $repo
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
    $script:CommitMessagesScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-commit-messages.ps1'
    $script:GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'check-commit-messages.ps1' {
    It 'Accepts conventional commit messages in an isolated repository' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommitMessagesSmokeRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'checks' 'check-commit-messages.ps1'
            Push-Location $repo
            try {
                & git commit --allow-empty -m 'feat(test): add commit message smoke fixture' -q 2>$null
            }
            finally {
                Pop-Location
            }

            Push-Location $repo
            try {
                $output = & pwsh -NoProfile -File $scriptPath -ArgumentList @('-Base', 'HEAD~1') 2>&1 | Out-String
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $exitCode | Should -Be 0
            $output | Should -Match 'Conventional Commits|Checking commits against base'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Documents Base parameter defaulting to origin/main in comment-based help' {
        $content = Get-Content -LiteralPath $script:CommitMessagesScript -Raw
        $content | Should -Match '\.PARAMETER Base'
        $content | Should -Match 'origin/main'
    }

    It 'Fails when a commit subject does not follow Conventional Commits format' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommitMessagesSmokeRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'checks' 'check-commit-messages.ps1'
            Push-Location $repo
            try {
                & git commit --allow-empty -m 'bad commit message without conventional format' -q 2>$null
                $output = & pwsh -NoProfile -File $scriptPath -ArgumentList @('-Base', 'HEAD~1') 2>&1 | Out-String
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $exitCode | Should -BeIn @(1, 2)
            $output | Should -Match 'invalid commit subjects|bad commit message'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Reports no commits to check when Base equals HEAD in an isolated repository' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommitMessagesSmokeRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'checks' 'check-commit-messages.ps1'
            Push-Location $repo
            try {
                $output = & pwsh -NoProfile -File $scriptPath -ArgumentList @('-Base', 'HEAD') 2>&1 | Out-String
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $exitCode | Should -Be 0
            $output | Should -Match 'No commits to check against HEAD'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
