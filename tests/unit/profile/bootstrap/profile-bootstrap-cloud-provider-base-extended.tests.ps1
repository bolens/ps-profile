# ===============================================
# profile-bootstrap-cloud-provider-base-extended.tests.ps1
# Execution tests for bootstrap/CloudProviderBase.ps1 behavior
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

function script:Reset-CloudProviderBaseState {
    Clear-FragmentLoaded -FragmentName 'cloud-provider-base' -ErrorAction SilentlyContinue
}

Describe 'profile.d/bootstrap/CloudProviderBase.ps1 extended scenarios' {
    BeforeEach {
        Reset-CloudProviderBaseState
    }

    It 'Registers cloud provider base helpers and marks the fragment loaded' {
        . (Join-Path $script:BootstrapDir 'CloudProviderBase.ps1')

        Get-Command Invoke-CloudCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-CloudProfile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'cloud-provider-base' | Should -Be $true
    }

    It 'Invoke-CloudCommand warns when the CLI is unavailable' {
        . (Join-Path $script:BootstrapDir 'CloudProviderBase.ps1')

        Set-TestCommandAvailabilityState -CommandName 'fakecloudcli' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('fakecloudcli', [ref]$null)
        }

        $output = & {
            Invoke-CloudCommand -CommandName 'fakecloudcli' -Arguments @('list') -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'fakecloudcli not found'
    }

    It 'Skips re-initialization when cloud-provider-base is already loaded' {
        . (Join-Path $script:BootstrapDir 'CloudProviderBase.ps1')
        $firstInvoke = Get-Command Invoke-CloudCommand -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'CloudProviderBase.ps1')

        (Get-Command Invoke-CloudCommand -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInvoke.ScriptBlock.ToString()
    }
}
