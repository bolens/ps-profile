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
            try {
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
            }

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $runnerDir 'run-lint.ps1')

            $result.Output | Should -Match 'Analyzing|Saved report to'
            $result.ExitCode | Should -BeIn @(0, 1)
            $reportFile = Get-ChildItem -LiteralPath $repo -Filter 'psscriptanalyzer-report.json' -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            $reportFile | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $reportFile.FullName | Should -BeTrue
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when an isolated fixture contains PSScriptAnalyzer error-level findings' {
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'RunLintViolationRepo'
        try {
            $profileDir = Join-Path $repo 'profile.d'
            $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:RunLintScript -Destination (Join-Path $runnerDir 'run-lint.ps1') -Force
            $settingsSource = Join-Path $script:TestRepoRoot 'PSScriptAnalyzerSettings.psd1'
            if (Test-Path -LiteralPath $settingsSource) {
                Copy-Item -LiteralPath $settingsSource -Destination (Join-Path $repo 'PSScriptAnalyzerSettings.psd1') -Force
            }
            Set-Content -LiteralPath (Join-Path $profileDir 'lint-violation.ps1') -Value @'
function Get-LintViolationFixture {
    ConvertTo-SecureString 'secret' -AsPlainText -Force
}
'@ -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                git add profile.d/lint-violation.ps1
                if (Test-Path -LiteralPath (Join-Path $repo 'PSScriptAnalyzerSettings.psd1')) {
                    git add PSScriptAnalyzerSettings.psd1
                }
                git commit -m 'init lint violation fixture' -q
            }
            finally {
                Pop-Location
            }

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $runnerDir 'run-lint.ps1')

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Saved report to|Error-level|PSScriptAnalyzer'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
