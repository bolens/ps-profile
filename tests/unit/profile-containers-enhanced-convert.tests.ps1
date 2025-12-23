# ===============================================
# profile-containers-enhanced-convert.tests.ps1
# Unit tests for Convert-ComposeToK8s function
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

Describe 'containers-enhanced.ps1 - Convert-ComposeToK8s' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('kompose', [ref]$null)
        }
        
        # Create test compose file
        $script:TestComposeFile = Join-Path $TestDrive 'docker-compose.yml'
        'version: "3"' | Out-File -FilePath $script:TestComposeFile -Encoding utf8
    }
    
    Context 'Tool not available' {
        It 'Returns null when kompose is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kompose' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'kompose' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestComposeFile } -MockWith { return $true }
            
            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Compose file validation' {
        It 'Returns error when compose file does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.yml' } -MockWith { return $false }
            
            { Convert-ComposeToK8s -ComposeFile 'nonexistent.yml' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Calls kompose with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'kompose'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestComposeFile } -MockWith { return $true }
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'kompose' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'convert'
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain $script:TestComposeFile
            $script:capturedArgs | Should -Contain '-o'
        }
        
        It 'Calls kompose with JSON format' {
            Setup-AvailableCommandMock -CommandName 'kompose'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestComposeFile } -MockWith { return $true }
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'kompose' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -Format 'json' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--json'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'kompose'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestComposeFile } -MockWith { return $true }
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'kompose' -MockWith { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles kompose execution errors' {
            Setup-AvailableCommandMock -CommandName 'kompose'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestComposeFile } -MockWith { return $true }
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'kompose' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

