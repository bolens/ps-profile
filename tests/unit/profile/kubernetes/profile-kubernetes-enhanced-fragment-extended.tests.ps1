# ===============================================
# profile-kubernetes-enhanced-fragment-extended.tests.ps1
# Execution tests for kubernetes-enhanced.ps1 fragment behavior
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

function script:Reset-KubernetesEnhancedFragmentState {
    Clear-FragmentLoaded -FragmentName 'kubernetes-enhanced' -ErrorAction SilentlyContinue
}

Describe 'profile.d/kubernetes-enhanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-KubernetesEnhancedFragmentState
    }

    It 'Loads kubernetes modules and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')

        Get-Command Set-KubeContext -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Tail-KubeLogs -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'kubernetes-enhanced' | Should -Be $true
    }

    It 'Set-KubeContext warns when kubectl is unavailable' {
        . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')

        foreach ($cmd in @('kubectx', 'kubectl', 'kubens')) {
            Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
        }

        $output = Set-KubeContext -List 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
    }

    It 'Skips re-initialization when kubernetes-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
        $firstContext = Get-Command Set-KubeContext -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')

        (Get-Command Set-KubeContext -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstContext.ScriptBlock.ToString()
    }
}
