. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Diagnostics Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'Diagnostics functions' {
        BeforeAll {
            $script:OriginalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            . (Join-Path $script:ProfileDir '59-diagnostics.ps1')
        }

        AfterAll {
            if ($script:OriginalDebug) {
                $env:PS_PROFILE_DEBUG = $script:OriginalDebug
            }
            else {
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Show-ProfileDiagnostic function is available when debug enabled' {
            Get-Command Show-ProfileDiagnostic -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-ProfileStartupTime function is available when debug enabled' {
            Get-Command Show-ProfileStartupTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Test-ProfileHealth function is available when debug enabled' {
            Get-Command Test-ProfileHealth -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-CommandUsageStats function is available when debug enabled' {
            Get-Command Show-CommandUsageStats -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-ProfileStartupTime runs without error' {
            { Show-ProfileStartupTime } | Should -Not -Throw
        }

        It 'Show-CommandUsageStats runs without error' {
            { Show-CommandUsageStats } | Should -Not -Throw
        }

        It 'Test-ProfileHealth runs without error' {
            { Test-ProfileHealth } | Should -Not -Throw
        }
    }
}
