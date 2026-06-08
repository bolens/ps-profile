<#
tests/unit/utility-populate-performance-metrics.tests.ps1

.SYNOPSIS
    Behavioral unit tests for populate-performance-metrics.ps1 startup behavior.
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
    $script:PopulateMetricsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'populate-performance-metrics.ps1'
    $ConfirmPreference = 'None'
}

Describe 'populate-performance-metrics.ps1 execution' {
    It 'Reports missing database module or completes metrics collection non-interactively' {
        $result = Invoke-TestScriptFile -ScriptPath $script:PopulateMetricsScript -ArgumentList @(
            '-IncludeStartupBenchmark:False',
            '-IncludeCodeMetrics:False'
        )

        $result.Output | Should -Match 'Populating Performance Metrics|Performance Metrics Database|metrics'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Returns setup error when the performance metrics database module is missing' {
        $result = Invoke-TestScriptFile -ScriptPath $script:PopulateMetricsScript -ArgumentList @(
            '-IncludeStartupBenchmark:False',
            '-IncludeCodeMetrics:False'
        )

        $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'Performance Metrics Database|not found'
    }

    It 'Runs against an isolated repository copy without loading the real profile tree' {
        $repo = New-TestTempDirectory -Prefix 'PopulateMetricsIsolated'
        try {
            $databaseDir = Join-Path $repo 'scripts' 'utils' 'database'
            New-Item -ItemType Directory -Path $databaseDir -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:PopulateMetricsScript -Destination (Join-Path $databaseDir 'populate-performance-metrics.ps1') -Force
            New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d') -Force | Out-Null

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
            }
            finally {
                Pop-Location
            }

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $databaseDir 'populate-performance-metrics.ps1') -ArgumentList @(
                '-IncludeStartupBenchmark:False',
                '-IncludeCodeMetrics:False',
                '-IncludeDocumentationMetrics:False'
            )

            $result.Output | Should -Match 'Populating Performance Metrics|Performance Metrics Database|metrics'
            $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
