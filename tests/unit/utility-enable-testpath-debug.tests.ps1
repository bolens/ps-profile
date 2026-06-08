<#
tests/unit/utility-enable-testpath-debug.tests.ps1

.SYNOPSIS
    Behavioral unit tests for enable-testpath-debug.ps1 output.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:EnableTestPathDebugScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'enable-testpath-debug.ps1'
    $ConfirmPreference = 'None'
}

Describe 'enable-testpath-debug.ps1 execution' {
    It 'Prints confirmation when Test-Path debug logging is enabled' {
        $result = Invoke-TestScriptFile -ScriptPath $script:EnableTestPathDebugScript

        $result.Output | Should -Match 'Test-Path debug logging enabled|PS_PROFILE_DEBUG_TESTPATH'
    }
}
