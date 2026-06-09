# ===============================================
# profile-lang-go-fragment-extended.tests.ps1
# Execution tests for lang-go.ps1 compatibility loader behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-LangGoFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-go' -ErrorAction SilentlyContinue
    Clear-FragmentLoaded -FragmentName 'lang-go-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-go.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangGoFragmentState
    }

    It 'Loads lang-go-tools helpers through the compatibility loader' {
        . (Join-Path $script:ProfileDir 'lang-go.ps1')

        Get-Command Release-GoProject -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-go' | Should -Be $true
    }

    It 'Release-GoProject warns when goreleaser is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-go.ps1')

        Set-TestCommandAvailabilityState -CommandName 'goreleaser' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('goreleaser', [ref]$null)
        }

        $output = Release-GoProject 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'goreleaser not found'
    }

    It 'Skips re-initialization when lang-go is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-go.ps1')
        $firstRelease = Get-Command Release-GoProject -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-go.ps1')

        (Get-Command Release-GoProject -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRelease.ScriptBlock.ToString()
    }
}
