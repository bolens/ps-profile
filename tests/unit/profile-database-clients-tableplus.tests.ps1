# ===============================================
# profile-database-clients-tableplus.tests.ps1
# Unit tests for Start-TablePlus function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
}

Describe 'database-clients.ps1 - Start-TablePlus' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('tableplus', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('TABLEPLUS', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('tableplus', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('TABLEPLUS', [ref]$null)
        }
        
        Remove-Item -Path "Function:\tableplus" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when tableplus is not available' {
            Mock-CommandAvailabilityPester -CommandName 'tableplus' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'tableplus' } -MockWith { return $null }
            
            $result = Start-TablePlus -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Starts tableplus without connection' {
            Setup-AvailableCommandMock -CommandName 'tableplus'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'tableplus' }
            }
            
            $result = Start-TablePlus
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'tableplus' }
        }
        
        It 'Starts tableplus with connection' {
            Setup-AvailableCommandMock -CommandName 'tableplus'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'tableplus' }
            }
            
            $connection = 'my-connection'
            $result = Start-TablePlus -Connection $connection
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $connection
        }
        
        It 'Handles process start errors' {
            Setup-AvailableCommandMock -CommandName 'tableplus'
            
            Mock Start-Process -MockWith {
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            $result = Start-TablePlus -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

