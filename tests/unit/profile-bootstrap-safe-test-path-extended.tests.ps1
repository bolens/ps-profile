<#
tests/unit/profile-bootstrap-safe-test-path-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/SafeTestPath.ps1'
}
Describe 'profile.d/bootstrap/SafeTestPath.ps1 extended scenarios' {
    It 'Documents safe Test-Path wrapper for null and empty paths' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Safe Test-Path wrapper'
        $c | Should -Match 'null/empty paths'
    }
    It 'Defines Test-NullSafePath with LiteralPath support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-NullSafePath'
        $c | Should -Match 'LiteralPath'
        $c | Should -Match 'PathType'
    }
    It 'Defines Trace-TestPath for diagnostic path tracing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Trace-TestPath'
        $c | Should -Match 'null or empty'
    }
}
