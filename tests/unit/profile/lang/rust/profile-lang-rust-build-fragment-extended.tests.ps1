# ===============================================
# profile-lang-rust-build-fragment-extended.tests.ps1
# Execution tests for lang-rust-build.ps1 fragment behavior
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

function script:Reset-LangRustBuildFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-rust-build' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-rust-build.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangRustBuildFragmentState
    }

    It 'Registers Rust build helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-rust-build.ps1')

        Get-Command Build-RustRelease -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command cargo-build-release -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-rust-build' | Should -Be $true
    }

    It 'Build-RustRelease warns when cargo is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-rust-build.ps1')

        Set-TestCommandAvailabilityState -CommandName 'cargo' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('cargo', [ref]$null)
            $null = $global:MissingToolWarnings.TryRemove('rustup', [ref]$null)
        }

        $output = & { Build-RustRelease } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'cargo not found'
    }

    It 'Skips re-initialization when lang-rust-build is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-rust-build.ps1')
        $firstBuild = Get-Command Build-RustRelease -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-rust-build.ps1')

        (Get-Command Build-RustRelease -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBuild.ScriptBlock.ToString()
    }
}
