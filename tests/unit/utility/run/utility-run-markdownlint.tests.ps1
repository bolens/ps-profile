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
    It 'prefers an available markdownlint command in-process' {
        function global:markdownlint {
            param([Parameter(ValueFromRemainingArguments)][object[]]$Arguments)
            $global:LASTEXITCODE = 0
        }

        $previousVersion = $env:MARKDOWNLINT_VERSION
        $env:MARKDOWNLINT_VERSION = '0.47.0'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:RunMarkdownlintScript 2>&1 | Out-String

            $output | Should -Match 'version: 0.47.0'
            $output | Should -Match 'markdownlint passed'
        }
        finally {
            Remove-Item Function:\markdownlint -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
            if ($null -eq $previousVersion) {
                Remove-Item Env:MARKDOWNLINT_VERSION -ErrorAction SilentlyContinue
            }
            else {
                $env:MARKDOWNLINT_VERSION = $previousVersion
            }
        }
    }

    It 'uses the npx fallback in-process when markdownlint is unavailable' {
        function global:npx {
            param([Parameter(ValueFromRemainingArguments)][object[]]$Arguments)
            $global:LASTEXITCODE = 0
        }

        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'markdownlint' }
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:RunMarkdownlintScript 2>&1 | Out-String

            $output | Should -Match 'markdownlint passed'
        }
        finally {
            Remove-Item Function:\npx -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'reports markdownlint violations in-process' {
        function global:markdownlint {
            param([Parameter(ValueFromRemainingArguments)][object[]]$Arguments)
            $global:LASTEXITCODE = 1
        }

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            { & $script:RunMarkdownlintScript 2>&1 } |
                Should -Throw -ExpectedMessage '*markdownlint found errors*'
        }
        finally {
            Remove-Item Function:\markdownlint -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
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
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'package.json') -Destination (Join-Path $repo 'package.json')
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
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'package.json') -Destination (Join-Path $repo 'package.json')
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

Describe 'run-markdownlint.ps1 canonical version selection' -Tag 'CanonicalVersion' {
    BeforeAll {
        $script:MarkdownlintVersionFixturePaths = @()
        function New-MarkdownlintVersionFixture {
            param(
                [string]$ManifestText = '{"devDependencies":{"markdownlint-cli":"9.8.7"}}',
                [switch]$MissingManifest
            )

            $repo = New-TestTempDirectory -Prefix 'MarkdownlintVersion'
            $script:MarkdownlintVersionFixturePaths += $repo
            $runnerDir = Join-Path $repo 'scripts/utils/code-quality'
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d') -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts/lib') -Destination (Join-Path $repo 'scripts/lib') -Recurse
            $runner = Join-Path $runnerDir 'run-markdownlint.ps1'
            Copy-Item -LiteralPath $script:RunMarkdownlintScript -Destination $runner
            $manifest = Join-Path $repo 'package.json'
            if (-not $MissingManifest) {
                Set-Content -LiteralPath $manifest -Value $ManifestText -Encoding UTF8
            }
            [PSCustomObject]@{ Root = $repo; Runner = $runner; Manifest = $manifest }
        }
    }

    AfterAll {
        foreach ($path in $script:MarkdownlintVersionFixturePaths) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    BeforeEach {
        $script:PreviousMarkdownlintVersion = $env:MARKDOWNLINT_VERSION
        $script:PreviousProfileTestMode = $env:PS_PROFILE_TEST_MODE
        Remove-Item Env:MARKDOWNLINT_VERSION -ErrorAction SilentlyContinue
        $env:PS_PROFILE_TEST_MODE = '1'
        $global:MarkdownlintNpxArguments = @()
        $global:MarkdownlintNpmCalls = 0
        function global:npx {
            param([Parameter(ValueFromRemainingArguments)][object[]]$Arguments)
            $global:MarkdownlintNpxArguments = $Arguments
            $global:LASTEXITCODE = 0
        }
        function global:npm {
            param([Parameter(ValueFromRemainingArguments)][object[]]$Arguments)
            $global:MarkdownlintNpmCalls++
            throw 'Unexpected npm invocation in an offline fixture'
        }
    }

    AfterEach {
        foreach ($name in @('markdownlint', 'npx', 'npm')) {
            Remove-Item "Function:\$name" -ErrorAction SilentlyContinue
        }
        if ($null -eq $script:PreviousMarkdownlintVersion) {
            Remove-Item Env:MARKDOWNLINT_VERSION -ErrorAction SilentlyContinue
        }
        else {
            $env:MARKDOWNLINT_VERSION = $script:PreviousMarkdownlintVersion
        }
        if ($null -eq $script:PreviousProfileTestMode) {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_TEST_MODE = $script:PreviousProfileTestMode
        }
        Remove-Variable MarkdownlintNpxArguments, MarkdownlintNpmCalls -Scope Global -ErrorAction SilentlyContinue
    }

    It 'reads a changed manifest pin for the log and offline npx fallback' {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'markdownlint' }
        $fixture = New-MarkdownlintVersionFixture
        $output = & $fixture.Runner 2>&1 | Out-String
        $output | Should -Match 'version: 9.8.7'
        $global:MarkdownlintNpxArguments | Should -Contain 'markdownlint-cli@9.8.7'

        Set-Content -LiteralPath $fixture.Manifest -Value '{"devDependencies":{"markdownlint-cli":"9.8.8"}}' -Encoding UTF8
        $output = & $fixture.Runner 2>&1 | Out-String
        $output | Should -Match 'version: 9.8.8'
        $global:MarkdownlintNpxArguments | Should -Contain 'markdownlint-cli@9.8.8'
        $global:MarkdownlintNpxArguments | Should -Contain '**/*.md'
        $global:MarkdownlintNpmCalls | Should -Be 0
    }

    It 'preserves an explicit override when the canonical manifest is absent' {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'markdownlint' }
        $fixture = New-MarkdownlintVersionFixture -MissingManifest
        $env:MARKDOWNLINT_VERSION = '0.47.0'
        $output = & $fixture.Runner 2>&1 | Out-String
        $output | Should -Match 'version: 0.47.0'
        $global:MarkdownlintNpxArguments | Should -Contain 'markdownlint-cli@0.47.0'
        $global:MarkdownlintNpmCalls | Should -Be 0
    }

    It 'rejects <Case> before invoking a package runner' -ForEach @(
        @{ Case = 'a missing manifest'; MissingManifest = $true; ManifestText = '{}' }
        @{ Case = 'invalid JSON'; MissingManifest = $false; ManifestText = '{' }
        @{ Case = 'a missing dependency pin'; MissingManifest = $false; ManifestText = '{"devDependencies":{}}' }
        @{ Case = 'a dependency range'; MissingManifest = $false; ManifestText = '{"devDependencies":{"markdownlint-cli":"^0.50.0"}}' }
        @{ Case = 'a registry tag'; MissingManifest = $false; ManifestText = '{"devDependencies":{"markdownlint-cli":"latest"}}' }
        @{ Case = 'a non-string pin'; MissingManifest = $false; ManifestText = '{"devDependencies":{"markdownlint-cli":50}}' }
    ) {
        $fixture = New-MarkdownlintVersionFixture -ManifestText $ManifestText -MissingManifest:$MissingManifest
        { & $fixture.Runner 2>&1 } | Should -Throw -ExpectedMessage '*Cannot resolve the canonical markdownlint-cli version*'
        $global:MarkdownlintNpxArguments.Count | Should -Be 0
        $global:MarkdownlintNpmCalls | Should -Be 0
    }
}
