<#
tests/unit/test-support-loader-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport.ps1'
}
Describe 'tests/TestSupport.ps1 extended scenarios' {
    It 'Documents test support utilities loader' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test support utilities loader'
        $c | Should -Match 'TestSupport subdirectory'
    }
    It 'Enables non-interactive test mode and suppresses confirmations' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PS_PROFILE_TEST_MODE'
        $c | Should -Match 'ConfirmPreference'
        $c | Should -Match 'PS_PROFILE_SUPPRESS_CONFIRMATIONS'
    }
    It 'Defines Get-TestSupportPath and Read-Host stub' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestSupportPath'
        $c | Should -Match 'Read-Host is disabled'
        $c | Should -Match 'Add-TestPerTestCleanup'
    }
}

