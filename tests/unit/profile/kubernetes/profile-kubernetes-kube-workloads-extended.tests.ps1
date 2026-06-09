# ===============================================
# profile-kubernetes-kube-workloads-extended.tests.ps1
# Execution tests for kubernetes-modules/kube-workloads.ps1 behavior
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

function script:Reset-KubeWorkloadsModuleState {
    Clear-FragmentLoaded -FragmentName 'kube-workloads' -ErrorAction SilentlyContinue
}

Describe 'profile.d/kubernetes-modules/kube-workloads.ps1 extended scenarios' {
    BeforeEach {
        Reset-KubeWorkloadsModuleState
    }

    It 'Registers workload helpers and marks the fragment loaded' {
        . (Join-Path $script:KubeModulesDir 'kube-workloads.ps1')

        Get-Command Get-KubeResources -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Exec-KubePod -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'kube-workloads' | Should -Be $true
    }

    It 'Get-KubeResources warns when kubectl is unavailable' {
        . (Join-Path $script:KubeModulesDir 'kube-workloads.ps1')

        Set-TestCommandAvailabilityState -CommandName 'kubectl' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
        }

        $output = Get-KubeResources -ResourceType 'pods' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
    }

    It 'Skips re-initialization when kube-workloads is already loaded' {
        . (Join-Path $script:KubeModulesDir 'kube-workloads.ps1')
        $firstGet = Get-Command Get-KubeResources -ErrorAction Stop

        . (Join-Path $script:KubeModulesDir 'kube-workloads.ps1')

        (Get-Command Get-KubeResources -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstGet.ScriptBlock.ToString()
    }
}
