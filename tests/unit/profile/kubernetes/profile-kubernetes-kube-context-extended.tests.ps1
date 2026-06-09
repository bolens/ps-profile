# ===============================================
# profile-kubernetes-kube-context-extended.tests.ps1
# Execution tests for kubernetes-modules/kube-context.ps1 behavior
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
    $script:KubeModulesDir = Join-Path $script:ProfileDir 'kubernetes-modules'
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-KubeContextModuleState {
    Clear-FragmentLoaded -FragmentName 'kube-context' -ErrorAction SilentlyContinue
}

Describe 'profile.d/kubernetes-modules/kube-context.ps1 extended scenarios' {
    BeforeEach {
        Reset-KubeContextModuleState
    }

    It 'Registers context helpers and marks the fragment loaded' {
        . (Join-Path $script:KubeModulesDir 'kube-context.ps1')

        Get-Command Set-KubeContext -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-KubeNamespace -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'kube-context' | Should -Be $true
    }

    It 'Set-KubeContext warns when kubectl and kubectx are unavailable' {
        . (Join-Path $script:KubeModulesDir 'kube-context.ps1')

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

    It 'Skips re-initialization when kube-context is already loaded' {
        . (Join-Path $script:KubeModulesDir 'kube-context.ps1')
        $firstContext = Get-Command Set-KubeContext -ErrorAction Stop

        . (Join-Path $script:KubeModulesDir 'kube-context.ps1')

        (Get-Command Set-KubeContext -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstContext.ScriptBlock.ToString()
    }
}
