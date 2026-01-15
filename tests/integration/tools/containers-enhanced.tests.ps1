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
    
    It 'Registers Clean-Containers function' {
        Get-Command -Name 'Clean-Containers' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Export-ContainerLogs function' {
        Get-Command -Name 'Export-ContainerLogs' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-ContainerStats function' {
        Get-Command -Name 'Get-ContainerStats' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Backup-ContainerVolumes function' {
        Get-Command -Name 'Backup-ContainerVolumes' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Restore-ContainerVolumes function' {
        Get-Command -Name 'Restore-ContainerVolumes' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Health-CheckContainers function' {
        Get-Command -Name 'Health-CheckContainers' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
    
    It 'Clean-Containers handles missing tool gracefully' {
        { Clean-Containers -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Export-ContainerLogs handles missing tool gracefully' {
        { Export-ContainerLogs -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Get-ContainerStats handles missing tool gracefully' {
        { Get-ContainerStats -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Backup-ContainerVolumes handles missing tool gracefully' {
        { Backup-ContainerVolumes -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Restore-ContainerVolumes handles missing tool gracefully' {
        { Restore-ContainerVolumes -BackupPath 'backup.tar.gz' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Health-CheckContainers handles missing tool gracefully' {
        { Health-CheckContainers -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

