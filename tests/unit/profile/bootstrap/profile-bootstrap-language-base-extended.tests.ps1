# ===============================================
# profile-bootstrap-language-base-extended.tests.ps1
# Execution tests for bootstrap/LanguageBase.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-LanguageBaseState {
    Clear-FragmentLoaded -FragmentName 'language-base' -ErrorAction SilentlyContinue
}

Describe 'profile.d/bootstrap/LanguageBase.ps1 extended scenarios' {
    BeforeEach {
        Reset-LanguageBaseState
    }

    It 'Registers language module registration helper and marks the fragment loaded' {
        . (Join-Path $script:BootstrapDir 'LanguageBase.ps1')

        Get-Command Register-LanguageModule -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'language-base' | Should -Be $true
    }

    It 'Register-LanguageModule warns when the language CLI is unavailable' {
        . (Join-Path $script:BootstrapDir 'LanguageBase.ps1')

        Set-TestCommandAvailabilityState -CommandName 'fakelangcli' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('fakelangcli', [ref]$null)
        }

        Register-LanguageModule -LanguageName 'FakeLang' -CommandName 'fakelangcli' | Out-Null

        $output = & { Invoke-FakeLang } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'fakelangcli not found'
    }

    It 'Skips re-initialization when language-base is already loaded' {
        . (Join-Path $script:BootstrapDir 'LanguageBase.ps1')
        $firstRegister = Get-Command Register-LanguageModule -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'LanguageBase.ps1')

        (Get-Command Register-LanguageModule -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRegister.ScriptBlock.ToString()
    }
}
