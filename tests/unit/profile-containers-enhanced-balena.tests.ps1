# ===============================================
# profile-containers-enhanced-balena.tests.ps1
# Unit tests for Deploy-Balena function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
}

Describe 'containers-enhanced.ps1 - Deploy-Balena' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('balena', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when balena is not available' {
            Mock-CommandAvailabilityPester -CommandName 'balena' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'balena' } -MockWith { return $null }
            
            $result = Deploy-Balena -Application 'my-app' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls balena push for push action' {
            Setup-AvailableCommandMock -CommandName 'balena'
            
            $script:capturedArgs = $null
            Mock -CommandName 'balena' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Pushed'
            }
            
            $result = Deploy-Balena -Application 'my-app' -Action 'push' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'push'
            $script:capturedArgs | Should -Contain 'my-app'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls balena logs for logs action' {
            Setup-AvailableCommandMock -CommandName 'balena'
            
            $script:capturedArgs = $null
            Mock -CommandName 'balena' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Log output'
            }
            
            $result = Deploy-Balena -Application 'my-app' -Action 'logs' -Device 'device-uuid' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'logs'
            $script:capturedArgs | Should -Contain 'my-app'
            $script:capturedArgs | Should -Contain '--device'
            $script:capturedArgs | Should -Contain 'device-uuid'
        }
        
        It 'Calls balena ssh for ssh action' {
            Setup-AvailableCommandMock -CommandName 'balena'
            
            $script:capturedArgs = $null
            Mock -CommandName 'balena' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'SSH connected'
            }
            
            $result = Deploy-Balena -Action 'ssh' -Device 'device-uuid' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'ssh'
            $script:capturedArgs | Should -Contain 'device-uuid'
        }
        
        It 'Returns error when Device is missing for ssh action' {
            Setup-AvailableCommandMock -CommandName 'balena'
            Mock Write-Error { }
            
            $result = Deploy-Balena -Action 'ssh' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Calls balena status for status action' {
            Setup-AvailableCommandMock -CommandName 'balena'
            
            $script:capturedArgs = $null
            Mock -CommandName 'balena' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Status output'
            }
            
            $result = Deploy-Balena -Application 'my-app' -Action 'status' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'status'
            $script:capturedArgs | Should -Contain '--application'
            $script:capturedArgs | Should -Contain 'my-app'
        }
        
        It 'Handles balena execution errors' {
            Setup-AvailableCommandMock -CommandName 'balena'
            
            Mock -CommandName 'balena' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Deploy-Balena -Application 'my-app' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

