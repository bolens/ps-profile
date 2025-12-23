# ===============================================
# profile-database-clients-sqlworkbench.tests.ps1
# Unit tests for Start-SqlWorkbench function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
    
    # Create test files
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestWorkspace = Join-Path $TestDrive 'workspace.xml'
        Set-Content -Path $script:TestWorkspace -Value '<?xml version="1.0"?><workspace></workspace>'
    }
}

Describe 'database-clients.ps1 - Start-SqlWorkbench' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('sql-workbench', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('SQL-WORKBENCH', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('sql-workbench', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('SQL-WORKBENCH', [ref]$null)
        }
        
        Remove-Item -Path "Function:\sql-workbench" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when sql-workbench is not available' {
            Mock-CommandAvailabilityPester -CommandName 'sql-workbench' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'sql-workbench' } -MockWith { return $null }
            
            $result = Start-SqlWorkbench -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Starts sql-workbench without workspace' {
            Setup-AvailableCommandMock -CommandName 'sql-workbench'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'sql-workbench' }
            }
            
            $result = Start-SqlWorkbench
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'sql-workbench' }
        }
        
        It 'Starts sql-workbench with workspace file' {
            Setup-AvailableCommandMock -CommandName 'sql-workbench'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'sql-workbench' }
            }
            
            $result = Start-SqlWorkbench -Workspace $script:TestWorkspace
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $script:TestWorkspace
        }
        
        It 'Returns error when workspace file does not exist' {
            Setup-AvailableCommandMock -CommandName 'sql-workbench'
            Mock Start-Process -MockWith { return [PSCustomObject]@{ Id = 12345 } }
            
            $result = Start-SqlWorkbench -Workspace 'C:\NonExistent\workspace.xml' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles process start errors' {
            Setup-AvailableCommandMock -CommandName 'sql-workbench'
            
            Mock Start-Process -MockWith {
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            $result = Start-SqlWorkbench -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

