# ===============================================
# profile-api-tools-fragment-extended.tests.ps1
# Execution tests for api-tools.ps1 fragment behavior
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

function script:Reset-ApiToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 'api-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/api-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-ApiToolsFragmentState
    }

    It 'Registers API tooling helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'api-tools.ps1')

        Get-Command Invoke-Bruno -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-Hurl -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'api-tools' | Should -Be $true
    }

    It 'Invoke-Bruno warns when bruno is unavailable' {
        . (Join-Path $script:ProfileDir 'api-tools.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('bruno')
        Set-TestCommandAvailabilityState -CommandName 'bruno' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('bruno', [ref]$null)
        }

        $output = Invoke-Bruno 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'bruno not found'
    }

    It 'Skips re-initialization when api-tools is already loaded' {
        . (Join-Path $script:ProfileDir 'api-tools.ps1')
        $firstBruno = Get-Command Invoke-Bruno -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'api-tools.ps1')

        (Get-Command Invoke-Bruno -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBruno.ScriptBlock.ToString()
    }
}
