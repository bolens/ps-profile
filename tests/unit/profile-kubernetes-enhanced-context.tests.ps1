# ===============================================
# profile-kubernetes-enhanced-context.tests.ps1
# Unit tests for Set-KubeContext and Set-KubeNamespace functions
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

Describe 'kubernetes-enhanced.ps1 - Set-KubeContext' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('kubectx', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('kubectl', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when neither kubectx nor kubectl is available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectx' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('kubectx', 'kubectl') } -MockWith { return $null }
            
            $result = Set-KubeContext -List -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'kubectx available' {
        It 'Lists contexts using kubectx' {
            Setup-AvailableCommandMock -CommandName 'kubectx'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectx' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'context1', 'context2'
            }
            
            $result = Set-KubeContext -List -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -BeNullOrEmpty
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Switches context using kubectx' {
            Setup-AvailableCommandMock -CommandName 'kubectx'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectx' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Set-KubeContext -ContextName 'my-context' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'my-context'
        }
    }
    
    Context 'kubectl fallback' {
        It 'Lists contexts using kubectl when kubectx not available' {
            # Clear cache first
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Ensure kubectx is not available
            Mock-CommandAvailabilityPester -CommandName 'kubectx' -Available $false
            # Ensure kubectl IS available (so function doesn't return early)
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            # Verify Test-CachedCommand returns true for kubectl
            Test-CachedCommand 'kubectl' | Should -Be $true
            
            $script:capturedArgs = @()
            Mock -CommandName 'kubectl' -MockWith { 
                # Capture all arguments passed to kubectl
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'context1', 'context2'
            }
            
            $result = Set-KubeContext -List -ErrorAction SilentlyContinue
            
            # Verify kubectl was called (function didn't return early)
            Should -Invoke 'kubectl' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'config'
            $script:capturedArgs | Should -Contain 'get-contexts'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'name'
        }
        
        It 'Switches context using kubectl when kubectx not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectx' -Available $false
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Set-KubeContext -ContextName 'my-context' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'config'
            $script:capturedArgs | Should -Contain 'use-context'
            $script:capturedArgs | Should -Contain 'my-context'
        }
    }
}

Describe 'kubernetes-enhanced.ps1 - Set-KubeNamespace' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('kubens', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('kubectl', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when neither kubens nor kubectl is available' {
            Mock-CommandAvailabilityPester -CommandName 'kubens' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('kubens', 'kubectl') } -MockWith { return $null }
            
            $result = Set-KubeNamespace -List -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'kubens available' {
        It 'Lists namespaces using kubens' {
            Setup-AvailableCommandMock -CommandName 'kubens'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubens' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'default', 'production'
            }
            
            $result = Set-KubeNamespace -List -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -BeNullOrEmpty
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Switches namespace using kubens' {
            Setup-AvailableCommandMock -CommandName 'kubens'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubens' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Set-KubeNamespace -Namespace 'production' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'production'
        }
    }
    
    Context 'kubectl fallback' {
        It 'Lists namespaces using kubectl when kubens not available' {
            # Clear cache first
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Ensure kubens is not available
            Mock-CommandAvailabilityPester -CommandName 'kubens' -Available $false
            # Ensure kubectl IS available (so function doesn't return early)
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            # Verify Test-CachedCommand returns true for kubectl
            Test-CachedCommand 'kubectl' | Should -Be $true
            
            $script:capturedArgs = @()
            Mock -CommandName 'kubectl' -MockWith { 
                # Capture all arguments passed to kubectl
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'namespace/default', 'namespace/production'
            }
            
            $result = Set-KubeNamespace -List -ErrorAction SilentlyContinue
            
            # Verify kubectl was called (function didn't return early)
            Should -Invoke 'kubectl' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'get'
            $script:capturedArgs | Should -Contain 'namespaces'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'name'
        }
        
        It 'Switches namespace using kubectl when kubens not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubens' -Available $false
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Set-KubeNamespace -Namespace 'production' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'config'
            $script:capturedArgs | Should -Contain 'set-context'
            $script:capturedArgs | Should -Contain '--current'
            $script:capturedArgs | Should -Contain '--namespace=production'
        }
    }
}

