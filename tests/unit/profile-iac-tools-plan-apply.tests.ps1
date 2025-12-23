# ===============================================
# profile-iac-tools-plan-apply.tests.ps1
# Unit tests for Plan-Infrastructure and Apply-Infrastructure functions
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

Describe 'iac-tools.ps1 - Plan-Infrastructure' {
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
            
            $result = Plan-Infrastructure -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'terraform available' {
        It 'Calls terraform plan with default settings' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Plan output'
            }
            
            $result = Plan-Infrastructure -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'plan'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls terraform plan with output file' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Plan output'
            }
            
            $result = Plan-Infrastructure -OutputFile 'plan.out' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-out'
            $script:capturedArgs | Should -Contain 'plan.out'
        }
        
        It 'Calls terraform plan with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Plan output'
            }
            
            $result = Plan-Infrastructure -Arguments '-detailed-exitcode' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-detailed-exitcode'
        }
    }
    
    Context 'opentofu fallback' {
        It 'Calls tofu plan when terraform not available' {
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
                return 'Plan output'
            }
            
            $result = Plan-Infrastructure -ErrorAction SilentlyContinue
            
            # Verify tofu was called (function didn't return early)
            Should -Invoke 'tofu' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'plan'
        }
        
        It 'Calls tofu plan when explicitly requested' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Setup-AvailableCommandMock -CommandName 'tofu'
            
            $script:capturedArgs = $null
            Mock -CommandName 'tofu' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Plan output'
            }
            
            $result = Plan-Infrastructure -Tool 'opentofu' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'plan'
        }
    }
}

Describe 'iac-tools.ps1 - Apply-Infrastructure' {
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
            
            $result = Apply-Infrastructure -ErrorAction SilentlyContinue -WhatIf:$false
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'terraform available' {
        It 'Calls terraform apply with default settings' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Apply output'
            }
            
            $result = Apply-Infrastructure -ErrorAction SilentlyContinue -WhatIf:$false
            
            $script:capturedArgs | Should -Contain 'apply'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls terraform apply with auto-approve' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Apply output'
            }
            
            $result = Apply-Infrastructure -AutoApprove -ErrorAction SilentlyContinue -WhatIf:$false
            
            $script:capturedArgs | Should -Contain '-auto-approve'
        }
        
        It 'Calls terraform apply with plan file' {
            Setup-AvailableCommandMock -CommandName 'terraform'
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'terraform' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Apply output'
            }
            
            $result = Apply-Infrastructure -PlanFile 'plan.out' -ErrorAction SilentlyContinue -WhatIf:$false
            
            $script:capturedArgs | Should -Contain 'plan.out'
        }
    }
}

