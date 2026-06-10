<#
tests/unit/library-fragment-loader-on-demand-extended.tests.ps1

.SYNOPSIS
    Extended behavioral tests for FragmentLoader path resolution and loading.
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
    $script:LibPath = Join-Path $script:RepoRoot 'scripts/lib'
    $script:TempRoot = New-TestTempDirectory -Prefix 'FragmentLoaderExtended'
    $script:TempProfileDir = Join-Path $script:TempRoot 'profile.d'
    New-Item -ItemType Directory -Path $script:TempProfileDir -Force | Out-Null

    $nestedDir = Join-Path $script:TempProfileDir 'nested'
    New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $nestedDir 'nested-fragment.ps1') -Value '# nested fragment' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:TempProfileDir 'root-fragment.ps1') -Value '# root fragment' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:TempProfileDir 'dep-child.ps1') -Value @'
# Requires: dep-parent
function Get-DepChild { 'child' }
'@ -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:TempProfileDir 'dep-parent.ps1') -Value @'
function Get-DepParent { 'parent' }
'@ -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:TempProfileDir 'requires-fragment.ps1') -Value @'
#Requires -Fragment "bootstrap"
function Get-RequiresFragment { 1 }
'@ -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:TempProfileDir 'dot-source-only.ps1') -Value @'
function Get-DotSourceOnly { 'loaded' }
'@ -Encoding UTF8

    Import-Module (Join-Path $script:LibPath 'fragment/FragmentCommandRegistry.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $script:LibPath 'fragment/FragmentLoader.psm1') -DisableNameChecking -Force -Global

    $script:OriginalProfileFragmentRoot = $null
    if (Get-Variable -Name 'ProfileFragmentRoot' -Scope Global -ErrorAction SilentlyContinue) {
        $script:OriginalProfileFragmentRoot = $global:ProfileFragmentRoot
    }

    $script:OriginalProfileDir = $null
    if (Get-Variable -Name 'ProfileDir' -Scope Global -ErrorAction SilentlyContinue) {
        $script:OriginalProfileDir = $global:ProfileDir
    }

    $script:OriginalFragmentLoaded = $null
    if (Get-Variable -Name '__psprofile_fragment_loaded' -Scope Global -ErrorAction SilentlyContinue) {
        $script:OriginalFragmentLoaded = $global:__psprofile_fragment_loaded
    }
}

function script:Reset-FragmentLoaderGlobals {
    Set-Variable -Name 'ProfileFragmentRoot' -Value $script:TempProfileDir -Scope Global
    Set-Variable -Name 'ProfileDir' -Value $script:TempProfileDir -Scope Global
    Set-Variable -Name '__psprofile_fragment_loaded' -Value @{} -Scope Global
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    function global:Write-StructuredWarning {
        param(
            [string]$Message,
            [string]$OperationName,
            [hashtable]$Context,
            [string]$Code
        )

        return $null
    }
}

AfterAll {
    if ($null -eq $script:OriginalProfileFragmentRoot) {
        Remove-Variable -Name 'ProfileFragmentRoot' -Scope Global -ErrorAction SilentlyContinue
    }
    else {
        Set-Variable -Name 'ProfileFragmentRoot' -Value $script:OriginalProfileFragmentRoot -Scope Global
    }

    if ($null -eq $script:OriginalProfileDir) {
        Remove-Variable -Name 'ProfileDir' -Scope Global -ErrorAction SilentlyContinue
    }
    else {
        Set-Variable -Name 'ProfileDir' -Value $script:OriginalProfileDir -Scope Global
    }

    if ($null -eq $script:OriginalFragmentLoaded) {
        Remove-Variable -Name '__psprofile_fragment_loaded' -Scope Global -ErrorAction SilentlyContinue
    }
    else {
        Set-Variable -Name '__psprofile_fragment_loaded' -Value $script:OriginalFragmentLoaded -Scope Global
    }

    Remove-Module FragmentLoader, FragmentCommandRegistry -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentLoader extended scenarios' {
    BeforeEach { Reset-FragmentLoaderGlobals }

    Context 'Get-ProfileDirectory' {
        It 'Prefers ProfileFragmentRoot when it exists' {
            $global:ProfileFragmentRoot = $script:TempProfileDir

            Get-ProfileDirectory | Should -Be $script:TempProfileDir
        }

        It 'Falls back to ProfileDir when ProfileFragmentRoot is unset' {
            $global:ProfileFragmentRoot = $null
            $global:ProfileDir = $script:TempProfileDir

            Get-ProfileDirectory | Should -Be $script:TempProfileDir
        }
    }

    Context 'Get-FragmentPath' {
        It 'Finds fragments nested under profile.d recursively' {
            $path = Get-FragmentPath -FragmentName 'nested-fragment'

            $path | Should -Be (Join-Path $script:TempProfileDir 'nested/nested-fragment.ps1')
        }

        It 'Returns the expected direct path when a fragment is missing' {
            $path = Get-FragmentPath -FragmentName 'missing-fragment-probe'

            $path | Should -Be (Join-Path $script:TempProfileDir 'missing-fragment-probe.ps1')
            Test-Path -LiteralPath $path | Should -Be $false
        }
    }

    Context 'Test-FragmentLoaded' {
        It 'Detects fragments marked in the global load map' {
            $global:__psprofile_fragment_loaded['mapped-fragment'] = $true

            Test-FragmentLoaded -FragmentName 'mapped-fragment' | Should -Be $true
        }

        It 'Detects fragments marked with the legacy Loaded global variable' {
            Set-Variable -Name 'legacyLoaded' -Value $true -Scope Global

            Test-FragmentLoaded -FragmentName 'legacy' | Should -Be $true

            Remove-Variable -Name 'legacyLoaded' -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-FragmentDependencies' {
        It 'Parses comma-separated Requires directives' {
            $deps = Get-FragmentDependencies -FragmentName 'dep-child' -FragmentPath (Join-Path $script:TempProfileDir 'dep-child.ps1')

            @($deps).Count | Should -BeGreaterOrEqual 1
            $deps | Should -Contain 'dep-parent'
        }

        It 'Parses Requires -Fragment directives' {
            $deps = Get-FragmentDependencies -FragmentName 'requires-fragment' -FragmentPath (Join-Path $script:TempProfileDir 'requires-fragment.ps1')

            @($deps).Count | Should -BeGreaterOrEqual 1
            $deps | Should -Contain 'bootstrap'
        }
    }

    Context 'Load-Fragment' {
        It 'Dot-sources fragments when Invoke-FragmentSafely is unavailable' {
            Remove-TestFunction -Name 'Invoke-FragmentSafely'

            $loaded = Load-Fragment -FragmentName 'dot-source-only' -LoadDependencies:$false

            $loaded | Should -Be $true
            Test-FragmentLoaded -FragmentName 'dot-source-only' | Should -Be $true
        }

        It 'Skips already-loaded fragments on subsequent calls' {
            $global:__psprofile_fragment_loaded['root-fragment'] = $true

            $loaded = Load-Fragment -FragmentName 'root-fragment' -LoadDependencies:$false

            $loaded | Should -Be $true
        }

        It 'Returns false for blank fragment names' {
            Load-Fragment -FragmentName '' | Should -Be $false
            Load-Fragment -FragmentName $null | Should -Be $false
        }
    }

    Context 'Load-FragmentForCommand' {
        It 'Loads the owning fragment for a registered command' {
            $null = Register-FragmentCommand -CommandName 'Get-DotSourceOnly' -FragmentName 'dot-source-only' -CommandType 'Function'
            Remove-TestFunction -Name 'Invoke-FragmentSafely'
            $global:__psprofile_fragment_loaded = @{}

            $loaded = Load-FragmentForCommand -CommandName 'Get-DotSourceOnly'

            $loaded | Should -Be $true
        }

        It 'Returns false when the command registry lookup fails' {
            Load-FragmentForCommand -CommandName 'unregistered-command-probe-999' | Should -Be $false
        }
    }

    Context 'Wide event fallback' {
        It 'Loads fragments when Invoke-WithWideEvent is unavailable' {
            Remove-TestFunction -Name 'Invoke-WithWideEvent'
            Remove-TestFunction -Name 'Invoke-FragmentSafely'
            $global:__psprofile_fragment_loaded = @{}

            $loaded = Load-Fragment -FragmentName 'root-fragment' -LoadDependencies:$false

            $loaded | Should -Be $true
        }
    }
}
