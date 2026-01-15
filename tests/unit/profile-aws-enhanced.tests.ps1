# ===============================================
# profile-aws-enhanced.tests.ps1
# Unit tests for enhanced AWS functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'aws.ps1')
}

Describe 'aws.ps1 - Enhanced Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('aws', [ref]$null)
        }
        
        # Mock AWS credentials file path
        $script:mockCredentialsPath = Join-Path $TestDrive '.aws' 'credentials'
        $null = New-Item -ItemType Directory -Path (Split-Path $script:mockCredentialsPath) -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Get-AwsCredentials' {
        It 'Returns null when aws is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Get-AwsCredentials -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Parses credentials file correctly' {
            Setup-AvailableCommandMock -CommandName 'aws'
            $mockContent = @(
                '[default]',
                'aws_access_key_id = AKIAIOSFODNN7EXAMPLE',
                'aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
                '[production]',
                'aws_access_key_id = AKIAI44QH8DHBEXAMPLE',
                'aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY'
            )
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*\.aws\credentials' } -MockWith { return $true }
            Mock Get-Content -ParameterFilter { $LiteralPath -like '*\.aws\credentials' } -MockWith { return $mockContent }
            
            # Mock USERPROFILE to point to TestDrive
            $originalUserProfile = $env:USERPROFILE
            $env:USERPROFILE = $TestDrive
            
            try {
                $result = Get-AwsCredentials -ErrorAction SilentlyContinue
                
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 2
                $result[0].ProfileName | Should -Be 'default'
                $result[1].ProfileName | Should -Be 'production'
            }
            finally {
                $env:USERPROFILE = $originalUserProfile
            }
        }
        
        It 'Masks access keys when ShowKeys is specified' {
            Setup-AvailableCommandMock -CommandName 'aws'
            $mockContent = @(
                '[default]',
                'aws_access_key_id = AKIAIOSFODNN7EXAMPLE'
            )
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*\.aws\credentials' } -MockWith { return $true }
            Mock Get-Content -ParameterFilter { $LiteralPath -like '*\.aws\credentials' } -MockWith { return $mockContent }
            
            $originalUserProfile = $env:USERPROFILE
            $env:USERPROFILE = $TestDrive
            
            try {
                $result = Get-AwsCredentials -ShowKeys -ErrorAction SilentlyContinue
                
                $result[0].AccessKeyId | Should -Match '^\w{4}\*\*\*\*\w{4}$'
            }
            finally {
                $env:USERPROFILE = $originalUserProfile
            }
        }
    }
    
    Context 'Test-AwsConnection' {
        It 'Returns false when aws is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Test-AwsConnection -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Handles missing aws command gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Test-AwsConnection -ErrorAction Stop } | Should -Not -Throw
        }
    }
    
    Context 'Get-AwsResources' {
        It 'Returns null when aws is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Get-AwsResources -Service 'ec2' -Action 'describe-instances' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Requires Service and Action parameters' {
            { Get-AwsResources -Service 'ec2' } | Should -Throw
            { Get-AwsResources -Action 'describe-instances' } | Should -Throw
        }
    }
    
    Context 'Export-AwsCredentials' {
        It 'Returns null when aws is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Export-AwsCredentials -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles missing aws command gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Export-AwsCredentials -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Switch-AwsAccount' {
        It 'Returns false when aws is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Switch-AwsAccount -ProfileName 'test' -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Requires ProfileName parameter' {
            { Switch-AwsAccount } | Should -Throw
        }
        
        It 'Switches profile and tests connection' {
            Setup-AvailableCommandMock -CommandName 'aws'
            Mock Set-AwsProfile -MockWith { $env:AWS_PROFILE = $ProfileName }
            Mock Test-AwsConnection -MockWith { return $true }
            
            $result = Switch-AwsAccount -ProfileName 'production' -ErrorAction SilentlyContinue
            
            $result | Should -Be $true
        }
        
        It 'Skips test when SkipTest is specified' {
            Setup-AvailableCommandMock -CommandName 'aws'
            Mock Set-AwsProfile -MockWith { $env:AWS_PROFILE = $ProfileName }
            
            $result = Switch-AwsAccount -ProfileName 'dev' -SkipTest -ErrorAction SilentlyContinue
            
            $result | Should -Be $true
        }
    }
    
    Context 'Get-AwsCosts' {
        It 'Returns null when aws is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Get-AwsCosts -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles missing aws command gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            { Get-AwsCosts -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
