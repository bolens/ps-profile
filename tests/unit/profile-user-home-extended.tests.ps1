<#
tests/unit/profile-user-home-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for cross-platform user home resolution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'UserHome.ps1')
}

AfterAll {
    Remove-Item Env:\HOME -ErrorAction SilentlyContinue
    Remove-Item Env:\USERPROFILE -ErrorAction SilentlyContinue
}

Describe 'UserHome extended scenarios' {
    Context 'Get-UserHome' {
        It 'Returns a non-empty path that exists on disk' {
            $homePath = Get-UserHome
            $homePath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $homePath | Should -Be $true
        }

        It 'Prefers HOME when it is set' {
            $originalHome = $env:HOME
            $testHome = New-TestTempDirectory -Prefix 'UserHomeExtended'

            try {
                $env:HOME = $testHome
                Get-UserHome | Should -Be $testHome
            }
            finally {
                if ($null -ne $originalHome) {
                    $env:HOME = $originalHome
                }
                else {
                    Remove-Item Env:\HOME -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Falls back to USERPROFILE when HOME is unset' {
            $originalHome = $env:HOME
            $originalProfile = $env:USERPROFILE
            $testProfile = New-TestTempDirectory -Prefix 'UserProfileExtended'

            try {
                Remove-Item Env:\HOME -ErrorAction SilentlyContinue
                $env:USERPROFILE = $testProfile
                Get-UserHome | Should -Be $testProfile
            }
            finally {
                if ($null -ne $originalHome) {
                    $env:HOME = $originalHome
                }
                if ($null -ne $originalProfile) {
                    $env:USERPROFILE = $originalProfile
                }
                else {
                    Remove-Item Env:\USERPROFILE -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Works with Join-Path for child directory resolution' {
            $homePath = Get-UserHome
            $childPath = Join-Path $homePath '.cache'
            $childPath | Should -Match ([regex]::Escape($homePath))
        }
    }
}
