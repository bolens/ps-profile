# ===============================================
# profile-kubernetes-enhanced-resources.tests.ps1
# Unit tests for Get-KubeResources, Start-Minikube, and Start-K9s functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Get-KubeResources' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('kubectl', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when kubectl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'kubectl' } -MockWith { return $null }
            
            $result = Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls kubectl get with resource type' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Pod list'
            }
            
            $result = Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'get'
            $script:capturedArgs | Should -Contain 'pods'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'wide'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls kubectl get with namespace and output format' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Deployment YAML'
            }
            
            $result = Get-KubeResources -ResourceType 'deployments' -Namespace 'production' -OutputFormat 'yaml' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-n'
            $script:capturedArgs | Should -Contain 'production'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'yaml'
        }
        
        It 'Calls kubectl get with specific resource name' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Pod details'
            }
            
            $result = Get-KubeResources -ResourceType 'pods' -ResourceName 'my-pod' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'my-pod'
        }
        
        It 'Handles kubectl execution errors' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            Mock -CommandName 'kubectl' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'kubernetes-enhanced.ps1 - Start-Minikube' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('minikube', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when minikube is not available' {
            Mock-CommandAvailabilityPester -CommandName 'minikube' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'minikube' } -MockWith { return $null }
            
            $result = Start-Minikube -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls minikube start with default profile' {
            Setup-AvailableCommandMock -CommandName 'minikube'
            
            $script:capturedArgs = $null
            Mock -CommandName 'minikube' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Minikube started'
            }
            
            $result = Start-Minikube -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'start'
            $script:capturedArgs | Should -Contain '-p'
            $script:capturedArgs | Should -Contain 'minikube'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls minikube start with custom profile and driver' {
            Setup-AvailableCommandMock -CommandName 'minikube'
            
            $script:capturedArgs = $null
            Mock -CommandName 'minikube' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Minikube started'
            }
            
            $result = Start-Minikube -Profile 'dev' -Driver 'docker' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-p'
            $script:capturedArgs | Should -Contain 'dev'
            $script:capturedArgs | Should -Contain '--driver'
            $script:capturedArgs | Should -Contain 'docker'
        }
        
        It 'Calls minikube status for status action' {
            Setup-AvailableCommandMock -CommandName 'minikube'
            
            $script:capturedArgs = @()
            Mock -CommandName 'minikube' -MockWith { 
                # Capture all arguments passed to minikube
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Running'
            }
            
            $result = Start-Minikube -Status -ErrorAction SilentlyContinue
            
            # Verify minikube was called
            Should -Invoke 'minikube' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'status'
            $script:capturedArgs | Should -Contain '-p'
            $script:capturedArgs | Should -Contain 'minikube'
        }
        
        It 'Handles minikube execution errors' {
            Setup-AvailableCommandMock -CommandName 'minikube'
            
            Mock -CommandName 'minikube' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Start-Minikube -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'kubernetes-enhanced.ps1 - Start-K9s' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('k9s', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when k9s is not available' {
            Mock-CommandAvailabilityPester -CommandName 'k9s' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'k9s' } -MockWith { return $null }
            
            $result = Start-K9s -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Launches k9s without arguments' {
            Setup-AvailableCommandMock -CommandName 'k9s'
            
            $script:capturedArgs = $null
            Mock -CommandName 'k9s' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            Start-K9s -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -BeNullOrEmpty
        }
        
        It 'Launches k9s with namespace' {
            Setup-AvailableCommandMock -CommandName 'k9s'
            
            $script:capturedArgs = $null
            Mock -CommandName 'k9s' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            Start-K9s -Namespace 'production' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-n'
            $script:capturedArgs | Should -Contain 'production'
        }
    }
}

