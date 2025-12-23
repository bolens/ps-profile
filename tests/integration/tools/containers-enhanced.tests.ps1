# ===============================================
# containers-enhanced.tests.ps1
# Integration tests for containers-enhanced.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
}

Describe 'containers-enhanced.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'containers-enhanced.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
        } | Should -Not -Throw
    }
}

Describe 'containers-enhanced.ps1 - Function Registration' {
    It 'Registers Start-PodmanDesktop function' {
        Get-Command -Name 'Start-PodmanDesktop' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Start-RancherDesktop function' {
        Get-Command -Name 'Start-RancherDesktop' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Convert-ComposeToK8s function' {
        Get-Command -Name 'Convert-ComposeToK8s' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Deploy-Balena function' {
        Get-Command -Name 'Deploy-Balena' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'containers-enhanced.ps1 - Graceful Degradation' {
    It 'Start-PodmanDesktop handles missing tool gracefully' {
        { Start-PodmanDesktop -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Start-RancherDesktop handles missing tool gracefully' {
        { Start-RancherDesktop -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Convert-ComposeToK8s handles missing tool gracefully' {
        { Convert-ComposeToK8s -ComposeFile 'docker-compose.yml' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Deploy-Balena handles missing tool gracefully' {
        { Deploy-Balena -Application 'test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

