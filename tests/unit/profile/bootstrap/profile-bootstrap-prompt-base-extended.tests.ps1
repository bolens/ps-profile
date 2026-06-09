# ===============================================
# profile-bootstrap-prompt-base-extended.tests.ps1
# Execution tests for bootstrap/PromptBase.ps1 behavior
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

function script:Reset-PromptBaseState {
    Clear-FragmentLoaded -FragmentName 'prompt-base' -ErrorAction SilentlyContinue
}

Describe 'profile.d/bootstrap/PromptBase.ps1 extended scenarios' {
    BeforeEach {
        Reset-PromptBaseState
    }

    It 'Registers prompt framework helpers and marks the fragment loaded' {
        . (Join-Path $script:BootstrapDir 'PromptBase.ps1')

        Get-Command Initialize-PromptFramework -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-PromptCommandAvailable -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'prompt-base' | Should -Be $true
    }

    It 'Test-PromptCommandAvailable warns when the prompt command is unavailable' {
        . (Join-Path $script:BootstrapDir 'PromptBase.ps1')

        Set-TestCommandAvailabilityState -CommandName 'fakepromptcli' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('fakepromptcli', [ref]$null)
        }

        $output = & {
            Test-PromptCommandAvailable -CommandName 'fakepromptcli' | Out-Null
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'fakepromptcli not found'
    }

    It 'Skips re-initialization when prompt-base is already loaded' {
        . (Join-Path $script:BootstrapDir 'PromptBase.ps1')
        $firstTest = Get-Command Test-PromptCommandAvailable -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'PromptBase.ps1')

        (Get-Command Test-PromptCommandAvailable -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTest.ScriptBlock.ToString()
    }
}
