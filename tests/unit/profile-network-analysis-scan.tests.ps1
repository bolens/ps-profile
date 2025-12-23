# ===============================================
# profile-network-analysis-scan.tests.ps1
# Unit tests for Invoke-NetworkScan function
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

Describe 'network-analysis.ps1 - Invoke-NetworkScan' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('sniffnet', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('trippy', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when sniffnet is not available' {
            Mock-CommandAvailabilityPester -CommandName 'sniffnet' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'sniffnet' } -MockWith { return $null }
            
            $result = Invoke-NetworkScan -Target '192.168.1.0/24' -Tool 'sniffnet' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns null when trippy is not available' {
            Mock-CommandAvailabilityPester -CommandName 'trippy' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'trippy' } -MockWith { return $null }
            
            $result = Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Sniffnet tool' {
        It 'Launches sniffnet' {
            Setup-AvailableCommandMock -CommandName 'sniffnet'
            
            $script:capturedFilePath = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
            }
            
            Invoke-NetworkScan -Target '192.168.1.0/24' -Tool 'sniffnet' -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'sniffnet'
        }
        
        It 'Handles Start-Process errors for sniffnet' {
            Setup-AvailableCommandMock -CommandName 'sniffnet'
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Invoke-NetworkScan -Target '192.168.1.0/24' -Tool 'sniffnet' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
    
    Context 'Trippy tool' {
        It 'Calls trippy with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'trippy'
            
            $script:capturedArgs = $null
            Mock -CommandName 'trippy' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Scan results'
            }
            
            $result = Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '192.168.1.1'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls trippy with JSON format' {
            Setup-AvailableCommandMock -CommandName 'trippy'
            
            $script:capturedArgs = $null
            Mock -CommandName 'trippy' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '{"results": "json"}'
            }
            
            $result = Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -OutputFormat 'json' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--json'
        }
        
        It 'Handles trippy execution errors' {
            Setup-AvailableCommandMock -CommandName 'trippy'
            
            Mock -CommandName 'trippy' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

