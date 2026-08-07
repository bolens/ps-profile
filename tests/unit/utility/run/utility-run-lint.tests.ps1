<#
tests/unit/utility-run-lint.tests.ps1

.SYNOPSIS
    Behavioral smoke test for run-lint.ps1 (full-repo PSScriptAnalyzer scan).
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
    $script:RunLintScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-lint.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-lint.ps1 execution' {
    It 'analyzes an isolated repository in-process and writes an empty report' {
        $repo = New-TestTempDirectory -Prefix 'RunLintInProcess'
        New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d'), (Join-Path $repo 'scripts') -Force | Out-Null
        Mock Invoke-ScriptAnalyzer { @() }

        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '3'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:RunLintScript -RepositoryRoot $repo -Verbose 4>&1
            $outputText = $output | Out-String
            $reportPath = Join-Path $repo 'scripts' 'data' 'psscriptanalyzer-report.json'

            $outputText | Should -Match 'Saved report'
            $outputText | Should -Match 'no issues found'
            Test-Path -LiteralPath $reportPath | Should -BeTrue
            @(Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json).Count | Should -Be 0
            Should -Invoke Invoke-ScriptAnalyzer -Times 2 -Exactly
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'reports analyzer findings from an isolated repository in-process' {
        $repo = New-TestTempDirectory -Prefix 'RunLintFinding'
        New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d'), (Join-Path $repo 'scripts') -Force | Out-Null
        Mock Invoke-ScriptAnalyzer {
            [pscustomobject]@{
                ScriptName = 'fixture.ps1'
                RuleName   = 'FixtureRule'
                Severity   = 'Error'
                Message    = 'fixture finding'
                Line       = 3
                Column     = 5
            }
        }

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            { & $script:RunLintScript -RepositoryRoot $repo 2>&1 } |
                Should -Throw -ExpectedMessage '*Errors found by PSScriptAnalyzer*'

            $reportPath = Join-Path $repo 'scripts' 'data' 'psscriptanalyzer-report.json'
            $report = @(Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json)
            $report | Should -HaveCount 2
            $report[0].RuleName | Should -Be 'FixtureRule'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'fails when an analyzer path cannot be processed in-process' {
        $repo = New-TestTempDirectory -Prefix 'RunLintFailure'
        New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d'), (Join-Path $repo 'scripts') -Force | Out-Null
        Mock Invoke-ScriptAnalyzer { throw 'analyzer failure probe' }

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            { & $script:RunLintScript -RepositoryRoot $repo 2>&1 } |
                Should -Throw -ExpectedMessage '*2 path(s) failed during linting*'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'Runs PSScriptAnalyzer and writes the JSON report' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'full-repo lint is too slow for CI'
            return
        }

        $reportPath = Join-Path $script:TestRepoRoot 'scripts' 'data' 'psscriptanalyzer-report.json'
        $beforeReport = if (Test-Path -LiteralPath $reportPath) {
            (Get-Item -LiteralPath $reportPath).LastWriteTimeUtc
        }
        else {
            $null
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:RunLintScript

        $result.Output | Should -Match 'Analyzing|Saved report to'
        Test-Path -LiteralPath $reportPath | Should -BeTrue
        if ($null -ne $beforeReport) {
            (Get-Item -LiteralPath $reportPath).LastWriteTimeUtc | Should -BeGreaterOrEqual $beforeReport
        }

        $result.ExitCode | Should -BeIn @(0, 1)
    }

    It 'Analyzes a narrow isolated repository and writes a JSON report' {
        $repo = New-TestTempDirectory -Prefix 'RunLintNarrowRepo'
        try {
            $profileDir = Join-Path $repo 'profile.d'
            $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $dataDir = Join-Path $repo 'scripts' 'data'
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path $dataDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:RunLintScript -Destination (Join-Path $runnerDir 'run-lint.ps1') -Force
            $settingsSource = Join-Path $script:TestRepoRoot 'PSScriptAnalyzerSettings.psd1'
            if (Test-Path -LiteralPath $settingsSource) {
                Copy-Item -LiteralPath $settingsSource -Destination (Join-Path $repo 'PSScriptAnalyzerSettings.psd1') -Force
            }
            Set-Content -LiteralPath (Join-Path $profileDir 'lint-fixture.ps1') -Value @'
function Get-RunLintFixture {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return 'ok'
}
'@ -Encoding UTF8

            Push-Location $repo
                        git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            git add profile.d/lint-fixture.ps1
            if (Test-Path -LiteralPath (Join-Path $repo 'PSScriptAnalyzerSettings.psd1')) {
                git add PSScriptAnalyzerSettings.psd1
            }
            git commit -m 'init lint fixture' -q
        }
        finally {
            Pop-Location

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $runnerDir 'run-lint.ps1')

            $result.Output | Should -Match 'Analyzing|Saved report to'
            $result.ExitCode | Should -BeIn @(0, 1)
            $reportFile = Get-ChildItem -LiteralPath $repo -Filter 'psscriptanalyzer-report.json' -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            $reportFile | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $reportFile.FullName | Should -BeTrue
        }
    }

    It 'Fails when an isolated fixture contains PSScriptAnalyzer error-level findings' {
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'RunLintViolationRepo'
        try {
            $violationDir = Join-Path $repo 'scripts' 'lint-fixtures'
            $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $violationDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:RunLintScript -Destination (Join-Path $runnerDir 'run-lint.ps1') -Force
            $settingsSource = Join-Path $script:TestRepoRoot 'PSScriptAnalyzerSettings.psd1'
            if (Test-Path -LiteralPath $settingsSource) {
                Copy-Item -LiteralPath $settingsSource -Destination (Join-Path $repo 'PSScriptAnalyzerSettings.psd1') -Force
            }
            Set-Content -LiteralPath (Join-Path $violationDir 'lint-violation.ps1') -Value @'
function Get-LintViolationFixture {
    ConvertTo-SecureString 'secret' -AsPlainText -Force
}
'@ -Encoding UTF8

            Push-Location $repo
                        git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            git add scripts/lint-fixtures/lint-violation.ps1
            if (Test-Path -LiteralPath (Join-Path $repo 'PSScriptAnalyzerSettings.psd1')) {
                git add PSScriptAnalyzerSettings.psd1
            }
            git commit -m 'init lint violation fixture' -q
        }
        finally {
            Pop-Location

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $runnerDir 'run-lint.ps1')

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Saved report to|Errors found by PSScriptAnalyzer'
            $reportFile = Get-ChildItem -LiteralPath $repo -Filter 'psscriptanalyzer-report.json' -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            $reportFile | Should -Not -BeNullOrEmpty
            @((Get-Content -LiteralPath $reportFile.FullName -Raw | ConvertFrom-Json)).Count | Should -BeGreaterThan 0
        }
    }
}
