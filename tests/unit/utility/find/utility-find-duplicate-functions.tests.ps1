<#
tests/unit/utility/find/utility-find-duplicate-functions.tests.ps1

.SYNOPSIS
    Behavioral tests for duplicate function scanning with isolated fragments.
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
    $script:DuplicateFunctionsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'find-duplicate-functions.ps1'
}

Describe 'find-duplicate-functions.ps1 fixture execution' {
    BeforeEach {
        $script:ProfilePath = New-TestTempDirectory -Prefix 'DuplicateFunctions'
        $script:PreviousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '2'
    }

    AfterEach {
        if ($null -eq $script:PreviousDebug) {
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_DEBUG = $script:PreviousDebug
        }
    }

    It 'passes for unique and global-scoped function definitions' {
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'alpha.ps1') -Value @'
function Get-UniqueAlpha { 'alpha' }
function global:Get-UniqueGlobal { 'global' }
'@ -Encoding UTF8

        { & $script:DuplicateFunctionsScript -ProfilePath $script:ProfilePath -Verbose } | Should -Not -Throw
    }

    It 'fails when fragments define the same function name' {
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'alpha.ps1') -Value "function Get-SharedFixture { 'alpha' }" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:ProfilePath 'beta.ps1') -Value "function global:Get-SharedFixture { 'beta' }" -Encoding UTF8

        { & $script:DuplicateFunctionsScript -ProfilePath $script:ProfilePath } | Should -Throw
    }

    It 'passes when the profile directory contains no scripts' {
        { & $script:DuplicateFunctionsScript -ProfilePath $script:ProfilePath } | Should -Not -Throw
    }
}
