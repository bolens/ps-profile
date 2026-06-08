<#
tests/unit/profile-bootstrap-error-handling-standard-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/ErrorHandlingStandard.ps1'
}
Describe 'profile.d/bootstrap/ErrorHandlingStandard.ps1 extended scenarios' {
    It 'Documents OpenTelemetry-style error handling and wide events' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'OpenTelemetry semantic conventions'
        $c | Should -Match 'wide events philosophy'
    }
    It 'Defines Write-WideEvent and Invoke-WithWideEvent helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-WideEvent'
        $c | Should -Match 'Invoke-WithWideEvent'
        $c | Should -Match 'Write-StructuredError'
    }
    It 'Marks error-handling-standard fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'WideEvents'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'error-handling-standard'"
    }
}
