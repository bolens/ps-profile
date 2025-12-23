# ===============================================
# profile-api-tools-httptoolkit.tests.ps1
# Unit tests for Start-HttpToolkit function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')
}

Describe 'api-tools.ps1 - Start-HttpToolkit' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('httptoolkit', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('HTTPTOOLKIT', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('httptoolkit', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('HTTPTOOLKIT', [ref]$null)
        }
        
        Remove-Item -Path "Function:\httptoolkit" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when httptoolkit is not available' {
            Mock-CommandAvailabilityPester -CommandName 'httptoolkit' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'httptoolkit' } -MockWith { return $null }
            
            $result = Start-HttpToolkit -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Starts httptoolkit with default port' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'
            
            $script:capturedArgs = $null
            $mockProcess = [PSCustomObject]@{ Id = 12345; ProcessName = 'httptoolkit' }
            Mock -CommandName Start-Process -MockWith { 
                param(
                    [string]$FilePath,
                    [string[]]$ArgumentList
                )
                $script:capturedArgs = $ArgumentList
                return $mockProcess
            }
            
            $result = Start-HttpToolkit
            
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be 12345
            Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq 'httptoolkit'
            }
            $script:capturedArgs | Should -Contain '--port'
            $script:capturedArgs | Should -Contain '8000'
        }
        
        It 'Starts httptoolkit with specified port' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'
            
            $script:capturedArgs = $null
            $mockProcess = [PSCustomObject]@{ Id = 12345; ProcessName = 'httptoolkit' }
            Mock -CommandName Start-Process -MockWith { 
                param(
                    [string]$FilePath,
                    [string[]]$ArgumentList
                )
                $script:capturedArgs = $ArgumentList
                return $mockProcess
            }
            
            $result = Start-HttpToolkit -Port 9000
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--port'
            $script:capturedArgs | Should -Contain '9000'
        }
        
        It 'Includes passthrough parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'
            
            $script:capturedArgs = $null
            $mockProcess = [PSCustomObject]@{ Id = 12345; ProcessName = 'httptoolkit' }
            Mock -CommandName Start-Process -MockWith { 
                param(
                    [string]$FilePath,
                    [string[]]$ArgumentList
                )
                $script:capturedArgs = $ArgumentList
                return $mockProcess
            }
            
            $result = Start-HttpToolkit -Passthrough
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--passthrough'
        }
        
        It 'Uses PassThru and NoNewWindow parameters for Start-Process' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'
            
            $mockProcess = [PSCustomObject]@{ Id = 12345; ProcessName = 'httptoolkit' }
            Mock -CommandName Start-Process -MockWith { 
                param(
                    [string]$FilePath,
                    [string[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                return $mockProcess
            }
            
            $result = Start-HttpToolkit
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
                $PassThru -eq $true -and $NoNewWindow -eq $true
            }
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'
            
            Mock -CommandName Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Failed to start process')
            }
            Mock Write-Error { }
            
            $result = Start-HttpToolkit -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

