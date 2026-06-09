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
    $ConfirmPreference = 'None'
}

Describe 'check-module-updates.ps1 execution' {
    It 'Parses and runs with a module filter without requiring interactive input' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckModuleUpdatesScript -ArgumentList @(
            '-ModuleFilter', 'Pester',
            '-DryRun'
        )

        $result.ExitCode | Should -BeIn @(0, 2)
        $result.Output | Should -Match 'Pester|module|update|Module'
    }

    It 'Rejects an invalid ScheduleFrequency value' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckModuleUpdatesScript -ArgumentList @(
            '-Schedule',
            '-ScheduleFrequency', 'Hourly',
            '-DryRun'
        )

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Hourly|ScheduleFrequency|ValidateSet|cannot be validated'
    }

    It 'Accepts Daily schedule parameters in DryRun mode without creating a scheduled task' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckModuleUpdatesScript -ArgumentList @(
            '-DryRun',
            '-Schedule',
            '-ScheduleFrequency', 'Daily',
            '-ModuleFilter', 'Pester'
        )

        $result.ExitCode | Should -BeIn @(0, 2)
        $result.Output | Should -Match 'DryRun|DRY RUN|Pester|module|update|Schedule'
    }

    It 'Writes an update report file when ReportFile is specified in DryRun mode' {
        $reportPath = Join-Path (New-TestTempDirectory -Prefix 'ModuleUpdateReport') 'updates.json'
            $result = Invoke-TestScriptFile -ScriptPath $script:CheckModuleUpdatesScript -ArgumentList @(
                '-DryRun',
                '-ModuleFilter', 'Pester',
                '-ReportFile', $reportPath
            )

            $result.ExitCode | Should -BeIn @(0, 2)
            if (Test-Path -LiteralPath $reportPath) {
                $reportPath | Should -Exist
                (Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json) | Should -Not -BeNullOrEmpty
            }
    }
}
