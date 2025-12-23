# ===============================================
# profile-database-clients-mongodb.tests.ps1
# Unit tests for Start-MongoDbCompass function
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

Describe 'database-clients.ps1 - Start-MongoDbCompass' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('mongodb-compass', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('MONGODB-COMPASS', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('mongodb-compass', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('MONGODB-COMPASS', [ref]$null)
        }
        
        Remove-Item -Path "Function:\mongodb-compass" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when mongodb-compass is not available' {
            Mock-CommandAvailabilityPester -CommandName 'mongodb-compass' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'mongodb-compass' } -MockWith { return $null }
            
            $result = Start-MongoDbCompass -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Starts mongodb-compass without connection string' {
            Setup-AvailableCommandMock -CommandName 'mongodb-compass'
            
            $script:capturedArgs = $null
            $script:processReturned = $false
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                $script:processReturned = $PassThru
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'mongodb-compass' }
            }
            
            $result = Start-MongoDbCompass
            
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be 12345
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'mongodb-compass' }
            $script:processReturned | Should -Be $true
        }
        
        It 'Starts mongodb-compass with connection string' {
            Setup-AvailableCommandMock -CommandName 'mongodb-compass'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$PassThru,
                    [switch]$NoNewWindow
                )
                $script:capturedArgs = $ArgumentList
                return [PSCustomObject]@{ Id = 12345; ProcessName = 'mongodb-compass' }
            }
            
            $connectionString = 'mongodb://localhost:27017'
            $result = Start-MongoDbCompass -ConnectionString $connectionString
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $connectionString
        }
        
        It 'Handles process start errors' {
            Setup-AvailableCommandMock -CommandName 'mongodb-compass'
            
            Mock Start-Process -MockWith {
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            $result = Start-MongoDbCompass -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

