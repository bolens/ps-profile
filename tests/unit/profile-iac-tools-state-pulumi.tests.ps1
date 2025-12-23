# ===============================================
# profile-iac-tools-state-pulumi.tests.ps1
# Unit tests for Get-TerraformState and Invoke-Pulumi functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'iac-tools.ps1')
}

Describe 'iac-tools.ps1 - Get-TerraformState' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('terraform', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('tofu', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when neither terraform nor opentofu is available' {
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('terraform', 'tofu') } -MockWith { return $null }
            
            $result = Get-TerraformState -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'terraform available' {
        It 'Calls terraform state show with default settings' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'State output'
            }
            
            $result = Get-TerraformState -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'state'
            $script:capturedArgs | Should -Contain 'show'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls terraform state show with resource address' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Resource state'
            }
            
            $result = Get-TerraformState -ResourceAddress 'aws_instance.web' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'aws_instance.web'
        }
        
        It 'Calls terraform state show with JSON format' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '{"state": "json"}'
            }
            
            $result = Get-TerraformState -OutputFormat 'json' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-json'
        }
        
        It 'Calls terraform state show with state file' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'State output'
            }
            
            $result = Get-TerraformState -StateFile 'custom.tfstate' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-state'
            $script:capturedArgs | Should -Contain 'custom.tfstate'
        }
    }
    
    Context 'opentofu fallback' {
        It 'Calls tofu state show when terraform not available' {
            # Clear cache first
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Ensure terraform is not available
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false
            # Ensure tofu IS available (so function doesn't return early)
            Setup-AvailableCommandMock -CommandName 'tofu'
            
            # Verify Test-CachedCommand returns true for tofu
            Test-CachedCommand 'tofu' | Should -Be $true
            
            $script:capturedArgs = @()
            Mock -CommandName 'tofu' -MockWith { 
                # Capture all arguments passed to tofu (splatted from array)
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'State output'
            }
            
            $result = Get-TerraformState -ErrorAction SilentlyContinue
            
            # Verify tofu was called (function didn't return early)
            Should -Invoke 'tofu' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'state'
            $script:capturedArgs | Should -Contain 'show'
        }
    }
}

Describe 'iac-tools.ps1 - Invoke-Pulumi' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('pulumi', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when pulumi is not available' {
            Mock-CommandAvailabilityPester -CommandName 'pulumi' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'pulumi' } -MockWith { return $null }
            
            $result = Invoke-Pulumi preview -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls pulumi with arguments' {
            Setup-AvailableCommandMock -CommandName 'pulumi'
            
            $script:capturedArgs = $null
            Mock -CommandName 'pulumi' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Preview output'
            }
            
            $result = Invoke-Pulumi preview -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'preview'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls pulumi with multiple arguments' {
            Setup-AvailableCommandMock -CommandName 'pulumi'
            
            $script:capturedArgs = $null
            Mock -CommandName 'pulumi' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Up output'
            }
            
            $result = Invoke-Pulumi up --yes -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'up'
            $script:capturedArgs | Should -Contain '--yes'
        }
        
        It 'Handles pulumi execution errors' {
            Setup-AvailableCommandMock -CommandName 'pulumi'
            
            Mock -CommandName 'pulumi' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('Command not found')
            }
            Mock Write-Error { }
            
            $result = Invoke-Pulumi preview -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

