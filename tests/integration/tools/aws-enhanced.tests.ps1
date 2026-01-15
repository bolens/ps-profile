# ===============================================
# aws-enhanced.tests.ps1
# Integration tests for aws.ps1 enhanced functions
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'aws.ps1 - Enhanced Functions Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'aws.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'aws.ps1')
                . (Join-Path $script:ProfileDir 'aws.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'aws.ps1')
        }
        
        It 'Registers Get-AwsCredentials function' {
            Get-Command -Name 'Get-AwsCredentials' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Test-AwsConnection function' {
            Get-Command -Name 'Test-AwsConnection' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-AwsResources function' {
            Get-Command -Name 'Get-AwsResources' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Export-AwsCredentials function' {
            Get-Command -Name 'Export-AwsCredentials' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Switch-AwsAccount function' {
            Get-Command -Name 'Switch-AwsAccount' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-AwsCosts function' {
            Get-Command -Name 'Get-AwsCosts' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'aws.ps1')
        }
        
        It 'Get-AwsCredentials handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Get-AwsCredentials -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Test-AwsConnection handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Test-AwsConnection -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Get-AwsResources handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Get-AwsResources -Service 'ec2' -Action 'describe-instances' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Export-AwsCredentials handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Export-AwsCredentials -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Switch-AwsAccount handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Switch-AwsAccount -ProfileName 'test' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Get-AwsCosts handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Get-AwsCosts -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'aws.ps1')
        }
        
        It 'Get-AwsCredentials returns array structure' {
            $result = Get-AwsCredentials -ErrorAction SilentlyContinue
            
            # May be null if aws not available or empty if no profiles
            if ($null -ne $result) {
                $result | Should -BeOfType [System.Array]
            }
        }
        
        It 'Test-AwsConnection returns boolean' {
            $result = Test-AwsConnection -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [bool]
        }
        
        It 'Switch-AwsAccount returns boolean' {
            $result = Switch-AwsAccount -ProfileName 'test' -SkipTest -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [bool]
        }
    }
}

