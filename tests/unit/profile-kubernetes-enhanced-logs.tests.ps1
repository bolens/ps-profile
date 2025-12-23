# ===============================================
# profile-kubernetes-enhanced-logs.tests.ps1
# Unit tests for Tail-KubeLogs function
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

Describe 'kubernetes-enhanced.ps1 - Tail-KubeLogs' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('stern', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('kubectl', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when neither stern nor kubectl is available' {
            Mock-CommandAvailabilityPester -CommandName 'stern' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('stern', 'kubectl') } -MockWith { return $null }
            
            $result = Tail-KubeLogs -Pattern 'my-app' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'stern available' {
        It 'Calls stern with pattern' {
            Setup-AvailableCommandMock -CommandName 'stern'
            
            $script:capturedArgs = $null
            Mock -CommandName 'stern' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Log output'
            }
            
            Tail-KubeLogs -Pattern 'my-app' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'my-app'
            $script:capturedArgs | Should -Contain '--tail'
            $script:capturedArgs | Should -Contain '0'
        }
        
        It 'Calls stern with namespace and container' {
            Setup-AvailableCommandMock -CommandName 'stern'
            
            $script:capturedArgs = $null
            Mock -CommandName 'stern' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Log output'
            }
            
            Tail-KubeLogs -Pattern 'nginx' -Namespace 'production' -Container 'web' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-n'
            $script:capturedArgs | Should -Contain 'production'
            $script:capturedArgs | Should -Contain '-c'
            $script:capturedArgs | Should -Contain 'web'
        }
    }
    
    Context 'kubectl fallback' {
        It 'Calls kubectl logs when stern not available' {
            Mock-CommandAvailabilityPester -CommandName 'stern' -Available $false
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'kubectl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Log output'
            }
            
            Tail-KubeLogs -Pattern 'my-app' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'logs'
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain '-l'
            $script:capturedArgs | Should -Contain 'app=my-app'
        }
    }
}

