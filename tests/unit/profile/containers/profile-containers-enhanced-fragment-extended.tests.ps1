# ===============================================
# profile-containers-enhanced-fragment-extended.tests.ps1
# Execution tests for containers-enhanced.ps1 fragment behavior
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

function script:Reset-ContainersEnhancedFragmentState {
    Clear-FragmentLoaded -FragmentName 'containers-enhanced' -ErrorAction SilentlyContinue
}

Describe 'profile.d/containers-enhanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-ContainersEnhancedFragmentState
    }

    It 'Registers enhanced container helper commands and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')

        Get-Command Start-PodmanDesktop -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Deploy-Balena -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clean-Containers -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'containers-enhanced' | Should -Be $true
    }

    It 'Start-PodmanDesktop warns when podman-desktop is unavailable' {
        . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('podman-desktop')
        Set-TestCommandAvailabilityState -CommandName 'podman-desktop' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('podman-desktop', [ref]$null)
        }

        $output = Start-PodmanDesktop 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'podman-desktop not found'
    }

    It 'Skips re-initialization when containers-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
        $firstDeploy = Get-Command Deploy-Balena -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')

        (Get-Command Deploy-Balena -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDeploy.ScriptBlock.ToString()
    }
}
