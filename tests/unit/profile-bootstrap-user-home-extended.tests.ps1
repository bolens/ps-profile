<#
tests/unit/profile-bootstrap-user-home-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/UserHome.ps1'
}
Describe 'profile.d/bootstrap/UserHome.ps1 extended scenarios' {
    It 'Documents cross-platform user home directory resolution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'User home directory resolution utility'
        $c | Should -Match 'cross-platform home directory'
    }
    It 'Defines Get-UserHome checking HOME and USERPROFILE' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-UserHome'
        $c | Should -Match 'env:HOME'
        $c | Should -Match 'env:USERPROFILE'
    }
    It 'Falls back to System.Environment UserProfile folder' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'GetFolderPath'
        $c | Should -Match 'UserProfile'
    }
}
