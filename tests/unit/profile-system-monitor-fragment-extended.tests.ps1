<#
tests/unit/profile-system-monitor-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system-monitor.ps1'
}
Describe 'profile.d/system-monitor.ps1 extended scenarios' {
    It 'Declares optional tier for server and development monitoring' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Environment: server, development'
    }
    It 'Loads diagnostics-system-monitor module from diagnostics-modules/monitoring' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'diagnostics-modules'
        $c | Should -Match 'diagnostics-system-monitor\.ps1'
    }
    It 'Reports module load failures through Write-ProfileError when debug is enabled' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-ProfileError'
        $c | Should -Match 'system-monitor'
    }
}
