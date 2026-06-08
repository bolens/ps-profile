<#
tests/unit/test-runner-timeout-handling-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-PesterWithTimeout runner messaging.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestTimeoutHandling.psm1') -Force -Global

    $script:PassingTestFile = New-TestTempFile -Prefix 'timeout-extended-pass' -Extension '.tests.ps1' -Content @"
Describe 'Timeout extended pass-through' {
    It 'passes quickly' {
        `$true | Should -Be `$true
    }
}
"@
}

Describe 'TestTimeoutHandling extended scenarios' {
    Context 'Invoke-PesterWithTimeout' {
        It 'Emits multi-run progress messaging without failing' {
            $config = New-PesterConfiguration
            $config.Run.PassThru = $true
            $config.Run.Exit = $false
            $config.Output.Verbosity = 'None'

            $output = @(Invoke-PesterWithTimeout -Config $config -TestPaths @($script:PassingTestFile) -Timeout 0 -RunNumber 2 -TotalRuns 3)
            $result = @($output | Where-Object { $null -ne $_ -and $_.PSObject.Properties['PassedCount'] }) | Select-Object -Last 1

            $result | Should -Not -BeNullOrEmpty
            $result.PassedCount | Should -BeGreaterThan 0
        }

        It 'Rejects mixed valid and invalid paths when timeout is enabled' {
            $config = New-PesterConfiguration
            $config.Run.PassThru = $true
            $config.Run.Exit = $false

            { Invoke-PesterWithTimeout -Config $config -TestPaths @($script:PassingTestFile, '/tmp/missing-timeout-target.tests.ps1') -Timeout 30 } |
                Should -Throw '*Invalid test paths detected*'
        }
    }
}
