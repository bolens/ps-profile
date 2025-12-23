# ===============================================
# kubernetes-enhanced.tests.ps1
# Integration tests for kubernetes-enhanced.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
        } | Should -Not -Throw
    }
}

Describe 'kubernetes-enhanced.ps1 - Function Registration' {
    It 'Registers Set-KubeContext function' {
        Get-Command -Name 'Set-KubeContext' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Set-KubeNamespace function' {
        Get-Command -Name 'Set-KubeNamespace' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Tail-KubeLogs function' {
        Get-Command -Name 'Tail-KubeLogs' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-KubeResources function' {
        Get-Command -Name 'Get-KubeResources' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Start-Minikube function' {
        Get-Command -Name 'Start-Minikube' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Start-K9s function' {
        Get-Command -Name 'Start-K9s' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'kubernetes-enhanced.ps1 - Graceful Degradation' {
    It 'Set-KubeContext handles missing tool gracefully' {
        { Set-KubeContext -List -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Set-KubeNamespace handles missing tool gracefully' {
        { Set-KubeNamespace -List -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Tail-KubeLogs handles missing tool gracefully' {
        { Tail-KubeLogs -Pattern 'test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Get-KubeResources handles missing tool gracefully' {
        { Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Start-Minikube handles missing tool gracefully' {
        { Start-Minikube -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Start-K9s handles missing tool gracefully' {
        { Start-K9s -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

