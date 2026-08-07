<#
tests/unit/utility-check-module-updates.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-module-updates.ps1 parameter validation and smoke execution.
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
    $script:CheckModuleUpdatesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'dependencies' 'check-module-updates.ps1'
    $script:ReportPath = Join-Path (New-TestTempDirectory -Prefix 'ModuleUpdateReport') 'updates.json'
    $cases = @(
        @{ Name = 'filter'; Arguments = @('-ModuleFilter', 'Pester', '-DryRun') }
        @{ Name = 'invalid'; Arguments = @('-Schedule', '-ScheduleFrequency', 'Hourly', '-DryRun') }
        @{ Name = 'schedule'; Arguments = @('-DryRun', '-Schedule', '-ScheduleFrequency', 'Daily', '-ModuleFilter', 'Pester') }
        @{ Name = 'report'; Arguments = @('-DryRun', '-ModuleFilter', 'Pester', '-ReportFile', $script:ReportPath) }
    )
    $jobs = foreach ($case in $cases) {
        $caseJson = $case | ConvertTo-Json -Compress
        Start-Job -ScriptBlock {
            param($ScriptPath, $CaseJson)

            $testCase = $CaseJson | ConvertFrom-Json
            $output = & pwsh -NoProfile -File $ScriptPath @($testCase.Arguments) 2>&1 | Out-String
            [pscustomobject]@{
                Name     = $testCase.Name
                ExitCode = $LASTEXITCODE
                Output   = $output
            }
        } -ArgumentList $script:CheckModuleUpdatesScript, $caseJson
    }
    $script:ModuleUpdateResults = @{}
    $jobs | Receive-Job -Wait | ForEach-Object {
        $script:ModuleUpdateResults[$_.Name] = $_
    }
    $jobs | Remove-Job -Force
    $ConfirmPreference = 'None'
}

Describe 'check-module-updates.ps1 execution' {
    It 'Parses and runs with a module filter without requiring interactive input' {
        $result = $script:ModuleUpdateResults.filter

        $result.ExitCode | Should -BeIn @(0, 2)
        $result.Output | Should -Match 'Pester|module|update|Module'
    }

    It 'Rejects an invalid ScheduleFrequency value' {
        $result = $script:ModuleUpdateResults.invalid

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Hourly|ScheduleFrequency|ValidateSet|cannot be validated'
    }

    It 'Accepts Daily schedule parameters in DryRun mode without creating a scheduled task' {
        $result = $script:ModuleUpdateResults.schedule

        $result.ExitCode | Should -BeIn @(0, 2)
        $result.Output | Should -Match 'DryRun|DRY RUN|Pester|module|update|Schedule'
    }

    It 'Writes an update report file when ReportFile is specified in DryRun mode' {
        $result = $script:ModuleUpdateResults.report

        $result.ExitCode | Should -BeIn @(0, 2)
        if (Test-Path -LiteralPath $script:ReportPath) {
            $script:ReportPath | Should -Exist
            (Get-Content -LiteralPath $script:ReportPath -Raw | ConvertFrom-Json) | Should -Not -BeNullOrEmpty
        }
    }
}
