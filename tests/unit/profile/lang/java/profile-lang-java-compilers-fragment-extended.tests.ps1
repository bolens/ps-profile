# ===============================================
# profile-lang-java-compilers-fragment-extended.tests.ps1
# Execution tests for lang-java-compilers.ps1 fragment behavior
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

function script:Reset-LangJavaCompilersFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-java-compilers' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-java-compilers.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangJavaCompilersFragmentState
    }

    It 'Registers Kotlin and Scala compiler helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-java-compilers.ps1')

        Get-Command Compile-Kotlin -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Compile-Scala -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command kotlinc -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-java-compilers' | Should -Be $true
    }

    It 'Compile-Kotlin warns when kotlinc is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-java-compilers.ps1')

        Set-TestCommandAvailabilityState -CommandName 'kotlinc' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('kotlinc', [ref]$null)
            $null = $global:MissingToolWarnings.TryRemove('kotlin', [ref]$null)
        }

        $output = & { Compile-Kotlin } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kotlinc not found'
    }

    It 'Skips re-initialization when lang-java-compilers is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-java-compilers.ps1')
        $firstKotlin = Get-Command Compile-Kotlin -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-java-compilers.ps1')

        (Get-Command Compile-Kotlin -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstKotlin.ScriptBlock.ToString()
    }
}
