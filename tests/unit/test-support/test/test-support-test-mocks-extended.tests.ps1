<#
tests/unit/test-support-test-mocks-extended.tests.ps1
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

