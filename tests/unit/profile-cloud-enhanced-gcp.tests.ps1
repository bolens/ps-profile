# ===============================================
# profile-cloud-enhanced-gcp.tests.ps1
# Unit tests for Set-GcpProject function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
}

Describe 'cloud-enhanced.ps1 - Set-GcpProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gcloud', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when gcloud is not available' {
            Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'gcloud' } -MockWith { return $null }
            
            $result = Set-GcpProject -List -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Lists projects when List is specified' {
            Setup-AvailableCommandMock -CommandName 'gcloud'
            
            $script:capturedArgs = $null
            Mock -CommandName 'gcloud' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Project list'
            }
            
            $result = Set-GcpProject -List -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'projects'
            $script:capturedArgs | Should -Contain 'list'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Switches project when ProjectId is specified' {
            Setup-AvailableCommandMock -CommandName 'gcloud'
            
            $script:capturedArgs = $null
            Mock -CommandName 'gcloud' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Set-GcpProject -ProjectId 'my-project' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'config'
            $script:capturedArgs | Should -Contain 'set'
            $script:capturedArgs | Should -Contain 'project'
            $script:capturedArgs | Should -Contain 'my-project'
        }
        
        It 'Shows current project when no parameters' {
            Setup-AvailableCommandMock -CommandName 'gcloud'
            
            $script:capturedArgs = $null
            Mock -CommandName 'gcloud' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'my-project'
            }
            
            $result = Set-GcpProject -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'config'
            $script:capturedArgs | Should -Contain 'get-value'
            $script:capturedArgs | Should -Contain 'project'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles gcloud execution errors' {
            Setup-AvailableCommandMock -CommandName 'gcloud'
            
            Mock -CommandName 'gcloud' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Set-GcpProject -List -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

