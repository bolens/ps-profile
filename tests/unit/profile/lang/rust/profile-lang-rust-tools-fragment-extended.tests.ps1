# ===============================================
# profile-lang-rust-tools-fragment-extended.tests.ps1
# Execution tests for lang-rust-tools.ps1 fragment behavior
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

function script:Reset-LangRustToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-rust-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-rust-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangRustToolsFragmentState
    }

    It 'Registers cargo-binstall and cargo-watch helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-rust-tools.ps1')

        Get-Command Install-RustBinary -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Watch-RustProject -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-rust-tools' | Should -Be $true
    }

    It 'Install-RustBinary warns when cargo-binstall is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-rust-tools.ps1')

        Set-TestCommandAvailabilityState -CommandName 'cargo-binstall' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('cargo-binstall', [ref]$null)
        }

        $output = & { Install-RustBinary -Packages @('test-package') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'cargo-binstall not found'
    }

    It 'Skips re-initialization when lang-rust-tools is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-rust-tools.ps1')
        $firstInstall = Get-Command Install-RustBinary -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-rust-tools.ps1')

        (Get-Command Install-RustBinary -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInstall.ScriptBlock.ToString()
    }
}
