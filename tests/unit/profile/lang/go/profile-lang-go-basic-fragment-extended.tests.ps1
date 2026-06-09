# ===============================================
# profile-lang-go-basic-fragment-extended.tests.ps1
# Execution tests for lang-go-basic.ps1 fragment behavior
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

function script:Reset-LangGoBasicFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-go-basic' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-go-basic.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangGoBasicFragmentState
    }

    It 'Registers Go helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-go-basic.ps1')

        Get-Command Invoke-GoRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command go-run -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-go-basic' | Should -Be $true
    }

    It 'Invoke-GoRun warns when go is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-go-basic.ps1')

        Set-TestCommandAvailabilityState -CommandName 'go' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('go', [ref]$null)
        }

        $output = Invoke-GoRun 'main.go' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'go not found'
    }

    It 'Skips re-initialization when lang-go-basic is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-go-basic.ps1')
        $firstGoRun = Get-Command Invoke-GoRun -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-go-basic.ps1')

        (Get-Command Invoke-GoRun -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstGoRun.ScriptBlock.ToString()
    }
}
