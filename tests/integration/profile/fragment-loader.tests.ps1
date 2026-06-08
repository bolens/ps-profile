<#
tests/integration/profile/fragment-loader.tests.ps1

.SYNOPSIS
    Integration tests for ProfileFragmentLoader and FragmentParallelLoading through Initialize-FragmentLoading.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibDir = Join-Path $script:RepoRoot 'scripts' 'lib'
    $script:FragmentLibDir = Join-Path $script:LibDir 'fragment'
    $script:FragmentLoadingModule = Join-Path $script:FragmentLibDir 'FragmentLoading.psm1'
    $script:FragmentErrorHandlingModule = Join-Path $script:FragmentLibDir 'FragmentErrorHandling.psm1'
    $script:LoaderModule = Join-Path $script:LibDir 'profile' 'ProfileFragmentLoader.psm1'

    Import-Module $script:LoaderModule -DisableNameChecking -Force -Global
    Import-Module (Join-Path $script:FragmentLibDir 'FragmentParallelLoading.psm1') -DisableNameChecking -Force -Global
}

function script:New-ProfileLoaderIntegrationFixture {
    param(
        [string]$Prefix = 'ProfileLoaderIntegration'
    )

    $tempDir = New-TestTempDirectory -Prefix $Prefix
    $profileD = Join-Path $tempDir 'profile.d'
    New-Item -ItemType Directory -Path $profileD -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $profileD 'bootstrap.ps1') -Value @'
$global:ProfileLoaderIntegrationBootstrap = $true
'@ -Encoding UTF8

    Set-Content -LiteralPath (Join-Path $profileD '20-integration-a.ps1') -Value @'
$global:ProfileLoaderIntegrationFragA = $true
'@ -Encoding UTF8

    Set-Content -LiteralPath (Join-Path $profileD '30-integration-b.ps1') -Value @'
$global:ProfileLoaderIntegrationFragB = $true
'@ -Encoding UTF8

    $bootstrap = Get-Item -LiteralPath (Join-Path $profileD 'bootstrap.ps1')
    $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($name in @('20-integration-a.ps1', '30-integration-b.ps1')) {
        [void]$fragments.Add((Get-Item -LiteralPath (Join-Path $profileD $name)))
    }

    return [PSCustomObject]@{
        TempDir     = $tempDir
        ProfileD    = $profileD
        Bootstrap   = $bootstrap
        Fragments   = $fragments
    }
}

function script:Invoke-ProfileLoaderIntegration {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture,

        [bool]$EnableParallelLoading = $false
    )

    $previousLoadAll = $env:PS_PROFILE_LOAD_ALL_FRAGMENTS
    $previousProxies = $env:PS_PROFILE_CREATE_PROXIES
    $env:PS_PROFILE_LOAD_ALL_FRAGMENTS = '1'
    $env:PS_PROFILE_CREATE_PROXIES = '0'

    try {
        Initialize-FragmentLoading `
            -FragmentsToLoad $Fixture.Fragments `
            -BootstrapFragment @($Fixture.Bootstrap) `
            -EnableParallelLoading $EnableParallelLoading `
            -FragmentLoadingModule $script:FragmentLoadingModule `
            -FragmentLoadingModuleExists $true `
            -FragmentLibDir $script:FragmentLibDir `
            -FragmentErrorHandlingModule $script:FragmentErrorHandlingModule `
            -FragmentErrorHandlingModuleExists $true `
            -ProfileD $Fixture.ProfileD
    }
    finally {
        if ($null -ne $previousLoadAll) { $env:PS_PROFILE_LOAD_ALL_FRAGMENTS = $previousLoadAll }
        else { Remove-Item Env:PS_PROFILE_LOAD_ALL_FRAGMENTS -ErrorAction SilentlyContinue }

        if ($null -ne $previousProxies) { $env:PS_PROFILE_CREATE_PROXIES = $previousProxies }
        else { Remove-Item Env:PS_PROFILE_CREATE_PROXIES -ErrorAction SilentlyContinue }
    }
}

function script:Clear-ProfileLoaderIntegrationGlobals {
    Remove-Variable -Name ProfileLoaderIntegrationBootstrap -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name ProfileLoaderIntegrationFragA -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name ProfileLoaderIntegrationFragB -Scope Global -ErrorAction SilentlyContinue
}

Describe 'ProfileFragmentLoader integration' {
    AfterEach {
        Clear-ProfileLoaderIntegrationGlobals
    }

    Context 'Initialize-FragmentLoading end-to-end' {
        It 'Loads bootstrap and test fragments when eager loading is enabled' {
            $fixture = New-ProfileLoaderIntegrationFixture
            try {
                Clear-ProfileLoaderIntegrationGlobals
                { Invoke-ProfileLoaderIntegration -Fixture $fixture -EnableParallelLoading $false } |
                    Should -Not -Throw

                $global:ProfileLoaderIntegrationBootstrap | Should -Be $true
                $global:ProfileLoaderIntegrationFragA | Should -Be $true
                $global:ProfileLoaderIntegrationFragB | Should -Be $true
            }
            finally {
                if ($fixture.TempDir -and (Test-Path -LiteralPath $fixture.TempDir)) {
                    Remove-Item -LiteralPath $fixture.TempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Skips fragment bodies when lazy loading remains enabled' {
            $fixture = New-ProfileLoaderIntegrationFixture
            $previousLoadAll = $env:PS_PROFILE_LOAD_ALL_FRAGMENTS
            $previousLazy = $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS
            Remove-Item Env:PS_PROFILE_LOAD_ALL_FRAGMENTS -ErrorAction SilentlyContinue
            $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS = '1'

            try {
                Clear-ProfileLoaderIntegrationGlobals
                Initialize-FragmentLoading `
                    -FragmentsToLoad $fixture.Fragments `
                    -BootstrapFragment @($fixture.Bootstrap) `
                    -EnableParallelLoading $false `
                    -FragmentLoadingModule $script:FragmentLoadingModule `
                    -FragmentLoadingModuleExists $true `
                    -FragmentLibDir $script:FragmentLibDir `
                    -FragmentErrorHandlingModule $script:FragmentErrorHandlingModule `
                    -FragmentErrorHandlingModuleExists $true `
                    -ProfileD $fixture.ProfileD

                $global:ProfileLoaderIntegrationBootstrap | Should -Be $true
                Get-Variable -Name ProfileLoaderIntegrationFragA -Scope Global -ErrorAction SilentlyContinue |
                    Should -BeNullOrEmpty
                Get-Variable -Name ProfileLoaderIntegrationFragB -Scope Global -ErrorAction SilentlyContinue |
                    Should -BeNullOrEmpty
            }
            finally {
                if ($null -ne $previousLoadAll) { $env:PS_PROFILE_LOAD_ALL_FRAGMENTS = $previousLoadAll }
                if ($null -ne $previousLazy) { $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS = $previousLazy }
                else { Remove-Item Env:PS_PROFILE_LAZY_LOAD_FRAGMENTS -ErrorAction SilentlyContinue }

                if ($fixture.TempDir -and (Test-Path -LiteralPath $fixture.TempDir)) {
                    Remove-Item -LiteralPath $fixture.TempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'FragmentParallelLoading through Initialize-FragmentLoading' {
        It 'Loads multiple fragments when parallel loading is enabled' {
            $fixture = New-ProfileLoaderIntegrationFixture
            try {
                Clear-ProfileLoaderIntegrationGlobals
                { Invoke-ProfileLoaderIntegration -Fixture $fixture -EnableParallelLoading $true } |
                    Should -Not -Throw

                $global:ProfileLoaderIntegrationFragA | Should -Be $true
                $global:ProfileLoaderIntegrationFragB | Should -Be $true
            }
            finally {
                if ($fixture.TempDir -and (Test-Path -LiteralPath $fixture.TempDir)) {
                    Remove-Item -LiteralPath $fixture.TempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
