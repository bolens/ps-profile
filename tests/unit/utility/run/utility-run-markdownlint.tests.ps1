<#
tests/unit/utility-run-markdownlint.tests.ps1

.SYNOPSIS
    Behavioral smoke test for run-markdownlint.ps1.
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
    $script:RunMarkdownlintScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-markdownlint.ps1'
    $script:MarkdownlintAvailable = [bool](Get-Command markdownlint -ErrorAction SilentlyContinue)
    $script:NpxAvailable = [bool](Get-Command npx -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'run-markdownlint.ps1 execution' {
    It 'Runs markdownlint or npx fallback without interactive prompts' {
        if (-not $script:MarkdownlintAvailable -and -not $script:NpxAvailable) {
            Set-ItResult -Skipped -Because 'markdownlint and npx are not available'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:RunMarkdownlintScript

        $result.ExitCode | Should -BeIn @(0, 1, 2)
        $result.Output | Should -Match 'markdownlint'
    }

    It 'Reports the configured MARKDOWNLINT_VERSION in output' {
        if (-not $script:MarkdownlintAvailable -and -not $script:NpxAvailable) {
            Set-ItResult -Skipped -Because 'markdownlint and npx are not available'
            return
        }

        $customVersion = '0.35.0'
        $result = Invoke-TestScriptFile -ScriptPath $script:RunMarkdownlintScript -EnvironmentVariables @{
            MARKDOWNLINT_VERSION = $customVersion
        }

        $result.ExitCode | Should -BeIn @(0, 1, 2)
        $result.Output | Should -Match "version: $customVersion"
    }

    It 'Fails when markdownlint finds violations in an isolated repository' {
        if (-not $script:MarkdownlintAvailable -and -not $script:NpxAvailable) {
            Set-ItResult -Skipped -Because 'markdownlint and npx are not available'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'MarkdownlintViolationRepo'
        $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:RunMarkdownlintScript -Destination (Join-Path $runnerDir 'run-markdownlint.ps1') -Force
        @(
            '# Bad Heading'
            ''
            '# Duplicate Top Level'
        ) | Set-Content -LiteralPath (Join-Path $repo 'bad-markdown.md') -Encoding UTF8
                Push-Location $repo
        try {
            git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            git add bad-markdown.md
            git commit -m 'init bad markdown' -q
                    $output = & pwsh -NoProfile -File (Join-Path $runnerDir 'run-markdownlint.ps1') 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
                $exitCode | Should -Be 1
        $output | Should -Match 'markdownlint found errors|markdownlint'
    }

    It 'Passes when markdownlint finds no violations in an isolated repository' {
        if (-not $script:MarkdownlintAvailable -and -not $script:NpxAvailable) {
            Set-ItResult -Skipped -Because 'markdownlint and npx are not available'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'MarkdownlintCleanRepo'
        $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:RunMarkdownlintScript -Destination (Join-Path $runnerDir 'run-markdownlint.ps1') -Force
        @(
            '# Clean Markdown Fixture'
            ''
            'This file should pass markdownlint.'
        ) | Set-Content -LiteralPath (Join-Path $repo 'clean-markdown.md') -Encoding UTF8
                Push-Location $repo
        try {
            git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            git add clean-markdown.md
            git commit -m 'init clean markdown' -q
                    $output = & pwsh -NoProfile -File (Join-Path $runnerDir 'run-markdownlint.ps1') 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
                $exitCode | Should -Be 0
        $output | Should -Match 'markdownlint passed'
    }
}
