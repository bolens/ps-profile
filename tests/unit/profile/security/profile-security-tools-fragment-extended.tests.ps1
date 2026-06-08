# ===============================================
# profile-security-tools-fragment-extended.tests.ps1
# Execution tests for security-tools.ps1 fragment behavior
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

function script:Reset-SecurityToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 'security-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/security-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-SecurityToolsFragmentState
    }

    It 'Registers security scanning helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'security-tools.ps1')

        Get-Command Invoke-GitLeaksScan -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-TruffleHogScan -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-OSVScan -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'security-tools' | Should -Be $true
    }

    It 'Invoke-GitLeaksScan warns when gitleaks is unavailable' {
        . (Join-Path $script:ProfileDir 'security-tools.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('gitleaks')
        Set-TestCommandAvailabilityState -CommandName 'gitleaks' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('gitleaks', [ref]$null)
        }

        $output = Invoke-GitLeaksScan 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gitleaks not found'
    }

    It 'Skips re-initialization when security-tools is already loaded' {
        . (Join-Path $script:ProfileDir 'security-tools.ps1')
        $firstScan = Get-Command Invoke-GitLeaksScan -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'security-tools.ps1')

        (Get-Command Invoke-GitLeaksScan -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstScan.ScriptBlock.ToString()
    }
}
