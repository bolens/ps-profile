<#
tests/unit/profile-main-loader-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 extended scenarios' {
    It 'Defines Get-ProfileRepositoryDirectory for repo root resolution' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'function script:Get-ProfileRepositoryDirectory'
        $c | Should -Match 'PS_PROFILE_REPO_ROOT'
    }
    It 'Writes immediate startup logging to powershell-profile-load.log' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'powershell-profile-load\.log'
        $c | Should -Match 'Profile execution started'
    }
    It 'Loads ProfileEnvFiles before debug level checks' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'ProfileEnvFiles\.psm1'
        $c | Should -Match 'Before .env load'
    }
    It 'Delegates feature modules to profile.d fragments' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'profile\.d'
        $c | Should -Match 'add functionality in'
    }
}
