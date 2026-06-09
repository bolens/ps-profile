# ===============================================
# profile-lang-java-version-fragment-extended.tests.ps1
# Execution tests for lang-java-version.ps1 fragment behavior
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

function script:Reset-LangJavaVersionFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-java-version' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-java-version.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangJavaVersionFragmentState
    }

    It 'Registers Set-JavaVersion and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-java-version.ps1')

        Get-Command Set-JavaVersion -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-java-version' | Should -Be $true
    }

    It 'Set-JavaVersion warns when java is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-java-version.ps1')

        Set-TestCommandAvailabilityState -CommandName 'java' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        $output = & { Set-JavaVersion } 2>&1 3>&1 | Out-String
        $output | Should -Match 'Java not found'
    }

    It 'Skips re-initialization when lang-java-version is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-java-version.ps1')
        $firstSetVersion = Get-Command Set-JavaVersion -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-java-version.ps1')

        (Get-Command Set-JavaVersion -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstSetVersion.ScriptBlock.ToString()
    }
}
