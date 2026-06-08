<#
tests/unit/test-support-test-mocks-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestMocks.ps1'
}
Describe 'tests/TestSupport/TestMocks.ps1 extended scenarios' {
    It 'Documents test mock initialization utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-TestMocks'
        $c | Should -Match 'Reset-TestIsolationState'
    }
    It 'Shadows editor and external command helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-AvailableEditor'
        $c | Should -Match 'Open-Editor'
        $c | Should -Match 'Open-VSCode'
    }
    It 'Defines Remove-TestArtifacts cleanup helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Remove-TestArtifacts'
        $c | Should -Match 'Get-TestStartProcessCapture'
    }
}

