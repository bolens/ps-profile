# ===============================================
# profile-lang-java-build-fragment-extended.tests.ps1
# Execution tests for lang-java-build.ps1 fragment behavior
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

function script:Reset-LangJavaBuildFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-java-build' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-java-build.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangJavaBuildFragmentState
    }

    It 'Registers Maven and Gradle build helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-java-build.ps1')

        Get-Command Build-Maven -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Build-Gradle -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command mvn -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-java-build' | Should -Be $true
    }

    It 'Build-Maven warns when mvn is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-java-build.ps1')

        Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('mvn', [ref]$null)
            $null = $global:MissingToolWarnings.TryRemove('maven', [ref]$null)
        }

        $output = & { Build-Maven } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mvn not found'
    }

    It 'Skips re-initialization when lang-java-build is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-java-build.ps1')
        $firstMaven = Get-Command Build-Maven -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-java-build.ps1')

        (Get-Command Build-Maven -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstMaven.ScriptBlock.ToString()
    }
}
