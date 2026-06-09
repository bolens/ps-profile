<#
tests/unit/test-runner-run-pester-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-pester.ps1 flags not covered by the base suite.
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
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'

    if (-not (Test-Path $script:RunPesterPath)) {
        throw "Test runner script not found at: $script:RunPesterPath"
    }

    function Clear-TestRunnerFlag {
        $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    }

    function Skip-IfModulesUnavailable {
        if (-not $script:RunPesterModulesWork) {
            Set-ItResult -Skipped -Because 'PesterConfig.psm1 cannot load — [PesterVerbosity] type requires Pester pre-loaded in session'
        }
    }

    $pesterConfigPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/PesterConfig.psm1'
    $configLoadResult = pwsh -NoProfile -Command "
        try { Import-Module '$pesterConfigPath' -Force -ErrorAction Stop; 'OK' }
        catch { 'FAIL:' + \$_.Exception.Message }
    " 2>&1
    $script:RunPesterModulesWork = $configLoadResult -notmatch '^FAIL:'

    $script:TestTempRoot = New-TestTempDirectory -Prefix 'RunPesterExtended'
    $script:DryRunTestFile = Join-Path $script:TestRepoRoot 'tests/unit/library/common/library-common.tests.ps1'

    function Invoke-RunPesterDryRun {
        param(
            [hashtable]$Parameters = @{}
        )

        $defaults = @{
            DryRun   = $true
            Suite    = 'Unit'
            TestFile = $script:DryRunTestFile
        }

        foreach ($key in $defaults.Keys) {
            if (-not $Parameters.ContainsKey($key)) {
                $Parameters[$key] = $defaults[$key]
            }
        }

        return & $script:RunPesterPath @Parameters
    }

    function Invoke-RunPesterDryRunToleratingErrors {
        param(
            [hashtable]$Parameters = @{}
        )

        $captured = [System.Collections.Generic.List[string]]::new()
                Invoke-RunPesterDryRun -Parameters $Parameters 2>&1 | ForEach-Object {
            $null = $captured.Add("$($_)")
        }
        $null = $captured.Add("EXIT:$LASTEXITCODE")
    }
    catch {
        $null = $captured.Add($_.Exception.Message)

        return $captured
    }
}

Describe 'run-pester.ps1 extended performance tracking' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }

    It 'Accepts TrackMemory with TrackPerformance in dry run mode' {
        $result = Invoke-RunPesterDryRun @{
            TrackPerformance = $true
            TrackMemory        = $true
        }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Accepts TrackCPU with TrackPerformance in dry run mode' {
        $result = Invoke-RunPesterDryRun @{
            TrackPerformance = $true
            TrackCPU           = $true
        }

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 extended coverage and reporting' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }

    It 'Accepts ShowCoverageSummary without enabling full coverage execution' {
        { Invoke-RunPesterDryRun @{ ShowCoverageSummary = $true } } | Should -Not -Throw
    }

    It 'Accepts IncludeReportDetails with AnalyzeResults dry run' {
        $reportPath = Join-Path $script:TestTempRoot 'extended-report.html'
        $result = Invoke-RunPesterDryRun @{
            AnalyzeResults       = $true
            ReportFormat         = 'HTML'
            ReportPath           = $reportPath
            IncludeReportDetails = $true
        }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Documents ShowCoverageSummary in comment help' {
        $content = Get-Content -LiteralPath $script:RunPesterPath -Raw
        $content | Should -Match '\.PARAMETER ShowCoverageSummary'
    }
}

Describe 'run-pester.ps1 extended path handling' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }

    It 'Handles a nonexistent TestFile path gracefully in dry run mode' {
        $missingFile = Join-Path $script:TestTempRoot 'missing-tests.tests.ps1'
        $result = Invoke-RunPesterDryRunToleratingErrors @{
            TestFile = $missingFile
        }

        $output = $result -join ' '
        ($output -Match 'Test file or directory not found|configured test paths exist|No test files|Recursive|Warning') | Should -Be $true
    }

    It 'Handles CompareBaseline when no baseline file exists yet' {
        $baselinePath = Join-Path $script:TestTempRoot 'missing-baseline.json'
        $result = Invoke-RunPesterDryRunToleratingErrors @{
            CompareBaseline = $true
            BaselinePath    = $baselinePath
        }

        $result | Should -Not -BeNullOrEmpty
    }
}
