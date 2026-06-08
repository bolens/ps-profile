<#
tests/unit/library-profile-fragment-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentConfig environment filtering.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileFragmentConfig.psm1') -DisableNameChecking -Force -Global

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentConfigExtended'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null

    foreach ($name in @('bootstrap.ps1', '10-alpha.ps1', '20-beta.ps1', '99-test-stub.ps1')) {
        Set-Content -LiteralPath (Join-Path $script:FragmentDir $name) -Value "# $name" -Encoding UTF8
    }

    $script:RealConfigModule = Join-Path $script:RepoRoot 'scripts/lib/fragment/FragmentConfig.psm1'
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_LOAD_ALL -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileFragmentConfig extended scenarios' {
    Context 'Test-EnvBool' {
        It 'Treats whitespace-padded true values as enabled' {
            Test-EnvBool -Value '  true  ' | Should -Be $true
            Test-EnvBool -Value ' 1 ' | Should -Be $true
        }

        It 'Treats unknown strings as disabled' {
            Test-EnvBool -Value 'yes' | Should -Be $false
            Test-EnvBool -Value 'enabled' | Should -Be $false
        }
    }

    Context 'Initialize-FragmentConfiguration environment sets' {
        AfterEach {
            Remove-Item Env:\PS_PROFILE_LOAD_ALL -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }

        It 'Disables fragments outside the active environment set' {
            if (-not (Test-Path -LiteralPath $script:RealConfigModule)) {
                Set-ItResult -Inconclusive -Because 'FragmentConfig module is unavailable in this workspace'
                return
            }

            $configPath = Join-Path $script:TempDir '.profile-fragments.json'
            @{
                environments = @{
                    minimal = @('bootstrap', '10-alpha')
                }
            } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding UTF8

            $env:PS_PROFILE_ENVIRONMENT = 'minimal'
            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:RealConfigModule

            $result.DisabledFragments | Should -Contain '20-beta'
            $result.DisabledFragments | Should -Not -Contain '10-alpha'
        }

        It 'Reports ProfileDExists false when profile.d is missing' {
            $missingProfileDir = New-TestTempDirectory -Prefix 'NoProfileD'
            $missingConfigModule = Join-Path $script:TempDir 'missing-config.psm1'

            try {
                $result = Initialize-FragmentConfiguration `
                    -ProfileDir $missingProfileDir `
                    -FragmentConfigModule $missingConfigModule

                $result.ProfileDExists | Should -Be $false
                $result.AllFragments | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -LiteralPath $missingProfileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns fragment library paths under scripts/lib/fragment' {
            $missingConfigModule = Join-Path $script:TempDir 'missing-config.psm1'

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $missingConfigModule

            $result.FragmentLibDir | Should -Match 'scripts[/\\]lib[/\\]fragment$'
            $result.FragmentLoadingModule | Should -Match 'FragmentLoading\.psm1$'
        }
    }
}
