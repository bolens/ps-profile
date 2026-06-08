<#
tests/unit/utility-debug-enable-testpath-debug.tests.ps1

.SYNOPSIS
    Behavioral unit tests for enable-testpath-debug.ps1.
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
    $script:EnableTestPathDebugScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'enable-testpath-debug.ps1'
    $ConfirmPreference = 'None'
}

Describe 'enable-testpath-debug.ps1 execution' {
    It 'Enables verbose Test-Path debug logging in the child process' {
        $result = Invoke-TestScriptFile -ScriptPath $script:EnableTestPathDebugScript -EnvironmentVariables @{
            PS_PROFILE_DEBUG_TESTPATH = $null
        }

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Test-Path debug logging enabled'
        $result.Output | Should -Match 'verbose'
        $result.Output | Should -Match 'Test-SafePath calls with null/empty paths'
    }
}
