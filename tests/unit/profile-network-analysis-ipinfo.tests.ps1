# ===============================================
# profile-network-analysis-ipinfo.tests.ps1
# Unit tests for Get-IpInfo function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'network-analysis.ps1')
}

Describe 'network-analysis.ps1 - Get-IpInfo' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('nali', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('ipinfo', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when nali is not available' {
            Mock-CommandAvailabilityPester -CommandName 'nali' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'nali' } -MockWith { return $null }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'nali' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns null when ipinfo is not available' {
            Mock-CommandAvailabilityPester -CommandName 'ipinfo' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'ipinfo' } -MockWith { return $null }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Nali tool' {
        It 'Calls nali with IP address' {
            Setup-AvailableCommandMock -CommandName 'nali'
            
            $script:capturedArgs = $null
            Mock -CommandName 'nali' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '8.8.8.8 [US]'
            }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'nali' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '8.8.8.8'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles nali execution errors' {
            Setup-AvailableCommandMock -CommandName 'nali'
            
            Mock -CommandName 'nali' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'nali' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
    
    Context 'Ipinfo tool' {
        It 'Calls ipinfo with IP address' {
            Setup-AvailableCommandMock -CommandName 'ipinfo'
            
            $script:capturedArgs = $null
            Mock -CommandName 'ipinfo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'IP: 8.8.8.8'
            }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '8.8.8.8'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls ipinfo with JSON format' {
            Setup-AvailableCommandMock -CommandName 'ipinfo'
            
            $script:capturedArgs = $null
            Mock -CommandName 'ipinfo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '{"ip": "8.8.8.8"}'
            }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -OutputFormat 'json' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--json'
        }
        
        It 'Handles ipinfo execution errors' {
            Setup-AvailableCommandMock -CommandName 'ipinfo'
            
            Mock -CommandName 'ipinfo' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

