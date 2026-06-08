# ===============================================
# containers-enhanced.tests.ps1
# Integration tests for containers-enhanced.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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
    BeforeEach {
        if ($global:CollectedMissingToolWarnings) {
            $global:CollectedMissingToolWarnings.Clear()
        }
        if ($global:MissingToolWarnings) {
            $global:MissingToolWarnings.Clear()
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
    }

    It 'Start-PodmanDesktop handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'podman-desktop' -Available $false
        $output = & { Start-PodmanDesktop -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'podman-desktop not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'podman-desktop'
    }
    
    It 'Start-RancherDesktop handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'rancher-desktop' -Available $false
        $output = & { Start-RancherDesktop -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'rancher-desktop not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'rancher-desktop'
    }
    
    It 'Convert-ComposeToK8s handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'kompose' -Available $false
        $output = & {
            Convert-ComposeToK8s -ComposeFile 'docker-compose.yml' -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kompose not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kompose'
    }
    
    It 'Deploy-Balena handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'balena' -Available $false
        $output = & { Deploy-Balena -Application 'test' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'balena not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'balena-cli'
    }
    
    It 'Clean-Containers handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'podman' -Available $false
        $output = & { Clean-Containers -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'docker/podman not found'
    }
    
    It 'Export-ContainerLogs handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'podman' -Available $false
        $output = & { Export-ContainerLogs -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'docker/podman not found'
    }
    
    It 'Get-ContainerStats handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'podman' -Available $false
        $output = & { Get-ContainerStats -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'docker/podman not found'
    }
    
    It 'Backup-ContainerVolumes handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'podman' -Available $false
        $output = & { Backup-ContainerVolumes -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'docker/podman not found'
    }
    
    It 'Restore-ContainerVolumes handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'podman' -Available $false
        $output = & {
            Restore-ContainerVolumes -BackupPath (Get-TestArtifactPath -FileName 'backup.tar.gz') -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'docker/podman not found'
    }
    
    It 'Health-CheckContainers handles missing tool gracefully' {
        Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'podman' -Available $false
        $output = & { Health-CheckContainers -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'docker/podman not found'
    }
}
