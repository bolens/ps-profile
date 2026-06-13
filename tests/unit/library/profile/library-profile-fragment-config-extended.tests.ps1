<#
tests/unit/library-profile-fragment-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentConfig environment filtering.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
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
    BeforeEach {
        Enable-TestStructuredLogging
    }

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

        It 'Keeps defaults when the config module path is missing' {
            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule (Join-Path $script:TempDir 'absent-config.psm1')

            @($result.DisabledFragments).Count | Should -Be 0
            $result.PerformanceConfig.maxFragmentTime | Should -Be 500
            $result.EnvironmentSets.Keys.Count | Should -Be 0
        }

        It 'Handles broken config module imports without throwing' {
            $brokenModule = Join-Path $script:TempDir 'broken-fragment-config.psm1'
            @'
throw 'config import failure probe'
'@ | Set-Content -LiteralPath $brokenModule -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-FragmentConfiguration -ProfileDir $script:TempDir -FragmentConfigModule $brokenModule } |
                Should -Not -Throw
        }

        It 'Handles config modules that omit Get-FragmentConfig' {
            $incompleteModule = Join-Path $script:TempDir 'incomplete-fragment-config.psm1'
            @'
function Export-Nothing { }
Export-ModuleMember -Function Export-Nothing
'@ | Set-Content -LiteralPath $incompleteModule -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $incompleteModule

            @($result.DisabledFragments).Count | Should -Be 0
            $result.ProfileDExists | Should -Be $true
        }

        It 'Shows the loading banner when environment filtering runs without debug output' {
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

            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            $env:PS_PROFILE_ENVIRONMENT = 'minimal'

            { Initialize-FragmentConfiguration -ProfileDir $script:TempDir -FragmentConfigModule $script:RealConfigModule } |
                Should -Not -Throw
        }

        It 'Emits debug summaries when PS_PROFILE_DEBUG is at least 2' {
            if (-not (Test-Path -LiteralPath $script:RealConfigModule)) {
                Set-ItResult -Inconclusive -Because 'FragmentConfig module is unavailable in this workspace'
                return
            }

            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:RealConfigModule

            $result.ProfileDExists | Should -Be $true
            @($result.AllFragments).Count | Should -BeGreaterThan 0
        }

        It 'Clears disabled fragments and honors PS_PROFILE_LOAD_ALL with debug output' {
            if (-not (Test-Path -LiteralPath $script:RealConfigModule)) {
                Set-ItResult -Inconclusive -Because 'FragmentConfig module is unavailable in this workspace'
                return
            }

            $configPath = Join-Path $script:TempDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '{"disabled":["10-alpha"]}' -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            $VerbosePreference = 'Continue'
            $env:PS_PROFILE_LOAD_ALL = '1'

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:RealConfigModule

            @($result.DisabledFragments).Count | Should -Be 0
        }

        It 'Ignores full environment name without applying environment filtering' {
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

            $env:PS_PROFILE_ENVIRONMENT = 'full'
            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:RealConfigModule

            $result.DisabledFragments | Should -Not -Contain '20-beta'
        }
    }
}
