<#
tests/unit/test-support-terminal-test-stubs-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TerminalTestStubs.ps1'
}
Describe 'tests/TestSupport/TerminalTestStubs.ps1 extended scenarios' {
    It 'Documents terminal integration test stubs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TerminalTestStubs.ps1'
        $c | Should -Match 'terminal integration tests'
    }
    It 'Defines Write-Host capture registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-TestWriteHostCapture'
        $c | Should -Match 'Clear-TestWriteHostCapture'
        $c | Should -Match 'TestWriteHostCaptures'
    }
    It 'Defines history and profile function stubs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-TestGetHistoryStub'
        $c | Should -Match 'Register-TestProfileFunctionStub'
    }
}

