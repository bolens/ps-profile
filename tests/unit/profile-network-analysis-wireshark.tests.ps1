# ===============================================
# profile-network-analysis-wireshark.tests.ps1
# Unit tests for Start-Wireshark function
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

Describe 'network-analysis.ps1 - Start-Wireshark' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('wireshark', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when wireshark is not available' {
            Mock-CommandAvailabilityPester -CommandName 'wireshark' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'wireshark' } -MockWith { return $null }
            
            $result = Start-Wireshark -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Launches wireshark without arguments' {
            Setup-AvailableCommandMock -CommandName 'wireshark'
            
            $script:capturedFilePath = $null
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
                $script:capturedArgs = $ArgumentList
            }
            
            Start-Wireshark -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'wireshark'
            $script:capturedArgs | Should -BeNullOrEmpty
        }
        
        It 'Launches wireshark with capture file' {
            Setup-AvailableCommandMock -CommandName 'wireshark'
            $testFile = Join-Path $TestDrive 'capture.pcap'
            'test content' | Out-File -FilePath $testFile -Encoding utf8
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $testFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedArgs = $ArgumentList
            }
            
            Start-Wireshark -CaptureFile $testFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain $testFile
        }
        
        It 'Launches wireshark with interface' {
            Setup-AvailableCommandMock -CommandName 'wireshark'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedArgs = $ArgumentList
            }
            
            Start-Wireshark -Interface 'Ethernet' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-i'
            $script:capturedArgs | Should -Contain 'Ethernet'
        }
        
        It 'Returns error when capture file does not exist' {
            Setup-AvailableCommandMock -CommandName 'wireshark'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.pcap' } -MockWith { return $false }
            Mock Write-Error { }
            
            Start-Wireshark -CaptureFile 'nonexistent.pcap' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'wireshark'
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Start-Wireshark -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

