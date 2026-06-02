# ===============================================
# kubernetes-enhanced.tests.ps1
# Integration tests for kubernetes-enhanced.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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
    
    It 'Registers Exec-KubePod function' {
        Get-Command -Name 'Exec-KubePod' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers PortForward-KubeService function' {
        Get-Command -Name 'PortForward-KubeService' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Describe-KubeResource function' {
        Get-Command -Name 'Describe-KubeResource' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Apply-KubeManifests function' {
        Get-Command -Name 'Apply-KubeManifests' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'kubernetes-enhanced.ps1 - Graceful Degradation' {
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

        foreach ($cmd in @('kubectx', 'kubectl', 'kubens', 'stern', 'minikube', 'k9s')) {
            Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
        }
    }

    It 'Set-KubeContext handles missing tool gracefully' {
        $output = & { Set-KubeContext -List -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'Set-KubeNamespace handles missing tool gracefully' {
        $output = & { Set-KubeNamespace -List -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'Tail-KubeLogs handles missing tool gracefully' {
        $output = & { Tail-KubeLogs -Pattern 'test' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'Get-KubeResources handles missing tool gracefully' {
        $output = & {
            Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'Start-Minikube handles missing tool gracefully' {
        $output = & { Start-Minikube -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'minikube not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'minikube'
    }
    
    It 'Start-K9s handles missing tool gracefully' {
        $output = & { Start-K9s -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'k9s not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'k9s'
    }
    
    It 'Exec-KubePod handles missing tool gracefully' {
        $output = & {
            Exec-KubePod -Pod 'test-pod' -Command 'ls' -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'PortForward-KubeService handles missing tool gracefully' {
        $output = & {
            PortForward-KubeService -Resource 'test-pod' -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'Describe-KubeResource handles missing tool gracefully' {
        $output = & {
            Describe-KubeResource -ResourceType 'pods' -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
    
    It 'Apply-KubeManifests handles missing tool gracefully' {
        Mock Test-Path -MockWith { return $true }
        $output = & {
            Apply-KubeManifests -Path 'manifests/' -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kubectl'
    }
}
