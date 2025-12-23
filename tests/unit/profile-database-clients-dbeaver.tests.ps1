# ===============================================
# profile-database-clients-dbeaver.tests.ps1
# Unit tests for Start-DBeaver function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
    
    # Create test directories
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestWorkspace = Join-Path $TestDrive 'dbeaver-workspace'
        New-Item -ItemType Directory -Path $script:TestWorkspace -Force | Out-Null
    }
}

Describe 'database-clients.ps1 - Start-DBeaver' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('dbeaver', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('DBEAVER', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('dbeaver', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('DBEAVER', [ref]$null)
        }
        
        Remove-Item -Path "Function:\dbeaver" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when dbeaver is not available' {
            Mock-CommandAvailabilityPester -CommandName 'dbeaver' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'dbeaver' } -MockWith { return $null }
            
            $result = Start-DBeaver -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Starts dbeaver without workspace' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'dbeaver' }
            }
            
            $result = Start-DBeaver
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'dbeaver' }
        }
        
        It 'Starts dbeaver with workspace directory' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'dbeaver' }
            }
            
            $result = Start-DBeaver -Workspace $script:TestWorkspace
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '-data'
            $script:capturedArgs | Should -Contain $script:TestWorkspace
        }
        
        It 'Returns error when workspace directory does not exist' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            Mock Start-Process -MockWith { return [PSCustomObject]@{ Id = 12345 } }
            
            $result = Start-DBeaver -Workspace 'C:\NonExistent\workspace' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles process start errors' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            
            Mock Start-Process -MockWith {
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            $result = Start-DBeaver -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

