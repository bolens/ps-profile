# ===============================================
# profile-lang-rust-audit-fragment-extended.tests.ps1
# Execution tests for lang-rust-audit.ps1 fragment behavior
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

function script:Reset-LangRustAuditFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-rust-audit' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-rust-audit.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangRustAuditFragmentState
    }

    It 'Registers cargo-audit helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')

        Get-Command Audit-RustProject -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-RustOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-rust-audit' | Should -Be $true
    }

    It 'Audit-RustProject warns when cargo-audit is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')

        Set-TestCommandAvailabilityState -CommandName 'cargo-audit' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('cargo-audit', [ref]$null)
        }

        $output = & { Audit-RustProject } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'cargo-audit not found'
    }

    It 'Skips re-initialization when lang-rust-audit is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')
        $firstAudit = Get-Command Audit-RustProject -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')

        (Get-Command Audit-RustProject -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstAudit.ScriptBlock.ToString()
    }
}
