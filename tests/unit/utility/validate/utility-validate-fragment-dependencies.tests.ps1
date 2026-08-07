<#
tests/unit/utility/validate/utility-validate-fragment-dependencies.tests.ps1

.SYNOPSIS
    Behavioral tests for dependency validation using isolated fragments.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ValidateDepsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'validate-fragment-dependencies.ps1'
}

Describe 'validate-fragment-dependencies.ps1 execution' {
    BeforeEach {
        $script:ProfilePath = New-TestTempDirectory -Prefix 'FragmentDependencies'
        $script:PreviousDebug = $env:PS_PROFILE_DEBUG
        Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }

    AfterEach {
        if ($null -eq $script:PreviousDebug) {
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_DEBUG = $script:PreviousDebug
        }
    }

    It 'reports a valid load order with portable debug timing' {
        $env:PS_PROFILE_DEBUG = '3'
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'alpha.ps1') -Value @'
function Get-FragmentDependencyAlpha { 'alpha' }
'@ -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'beta.ps1') -Value @'
#Requires -Fragment 'alpha'
function Get-FragmentDependencyBeta { 'beta' }
'@ -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:ProfilePath '01-ignored.ps1') -Value '# ignored' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'files-module-registry.ps1') -Value '# ignored' -Encoding UTF8

        { & $script:ValidateDepsScript -ProfilePath $script:ProfilePath -Verbose } | Should -Not -Throw
    }

    It 'reports a missing fragment dependency' {
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'consumer.ps1') -Value @'
#Requires -Fragment 'missing-fragment'
function Get-FragmentDependencyConsumer { 'consumer' }
'@ -Encoding UTF8

        {
            & $script:ValidateDepsScript -ProfilePath $script:ProfilePath
        } | Should -Throw
    }

    It 'reports circular fragment dependencies' {
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'alpha.ps1') -Value @'
#Requires -Fragment 'beta'
function Get-FragmentDependencyAlpha { 'alpha' }
'@ -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'beta.ps1') -Value @'
#Requires -Fragment 'alpha'
function Get-FragmentDependencyBeta { 'beta' }
'@ -Encoding UTF8

        {
            & $script:ValidateDepsScript -ProfilePath $script:ProfilePath
        } | Should -Throw
    }
}
