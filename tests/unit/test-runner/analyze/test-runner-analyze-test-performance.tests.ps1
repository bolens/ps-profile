<#
tests/unit/test-runner-analyze-test-performance.tests.ps1

.SYNOPSIS
    Behavioral unit tests for analyze-test-performance.ps1 parameter validation.
#>

function global:Invoke-AnalyzeTestPerformanceScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:AnalyzeTestPerformanceScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
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
    $script:AnalyzeTestPerformanceScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'analyze-test-performance.ps1'
    $ConfirmPreference = 'None'
}

Describe 'analyze-test-performance.ps1 execution' {
    It 'Rejects TopN values outside the allowed range' {
        $result = Invoke-AnalyzeTestPerformanceScript -ArgumentList @('-TopN', '0')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'TopN|range|validation'
    }

    It 'Validates Suite values without enum load errors' {
        $result = Invoke-AnalyzeTestPerformanceScript -ArgumentList @('-Suite', 'Bogus')

        $result.Output | Should -Not -Match 'Unable to find type \[TestSuite\]'
        $result.Output | Should -Match 'Bogus|ValidateSet|cannot be validated'
        $result.ExitCode | Should -Not -Be 0
    }

    It 'Exits successfully when no unit test paths exist in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'AnalyzePerfEmptyRepo'
        try {
            $codeQualityDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $modulesDir = Join-Path $codeQualityDir 'modules'
            $null = New-Item -ItemType Directory -Path $modulesDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:AnalyzeTestPerformanceScript -Destination (Join-Path $codeQualityDir 'analyze-test-performance.ps1') -Force
            Get-ChildItem -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'modules') -Filter '*.psm1' |
                Copy-Item -Destination $modulesDir -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $result = Invoke-AnalyzeTestPerformanceScript -ArgumentList @('-Suite', 'Unit')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'No test paths found for suite: Unit'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Analyzes a single fast unit test file in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'AnalyzePerfSingleTest'
        try {
            $codeQualityDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $modulesDir = Join-Path $codeQualityDir 'modules'
            $unitDir = Join-Path $repo 'tests' 'unit'
            $testFile = Join-Path $unitDir 'perf-sample.tests.ps1'
            $null = New-Item -ItemType Directory -Path $modulesDir -Force
            $null = New-Item -ItemType Directory -Path $unitDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:AnalyzeTestPerformanceScript -Destination (Join-Path $codeQualityDir 'analyze-test-performance.ps1') -Force
            Get-ChildItem -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'modules') -Filter '*.psm1' |
                Copy-Item -Destination $modulesDir -Force
            Set-Content -LiteralPath $testFile -Value @'
Describe 'perf sample' {
    It 'passes quickly' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $result = Invoke-AnalyzeTestPerformanceScript -ArgumentList @('-Suite', 'Unit', '-TopN', '5')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Analyzing test performance for suite: Unit'
            $result.Output | Should -Match 'Test Performance Analysis Report|=== Summary ==='
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
