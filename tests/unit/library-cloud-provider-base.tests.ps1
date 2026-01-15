# ===============================================
# library-cloud-provider-base.tests.ps1
# Unit tests for CloudProviderBase.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load CloudProviderBase module
    . (Join-Path $script:ProfileDir 'bootstrap' 'CloudProviderBase.ps1')
}

BeforeEach {
    # Clear command cache
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    
    if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
        $null = $global:TestCachedCommandCache.TryRemove('aws', [ref]$null)
        $null = $global:TestCachedCommandCache.TryRemove('az', [ref]$null)
        $null = $global:TestCachedCommandCache.TryRemove('gcloud', [ref]$null)
    }
}

Describe 'CloudProviderBase.ps1 - Invoke-CloudCommand' {
    Context 'Command Detection' {
        It 'Returns null when command is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Shows warning when command is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $warningOutput = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') 6>&1
            
            $warningOutput | Should -Match 'aws'
        }
        
        It 'Executes command when available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName '&' -MockWith {
                param($CommandName, $Arguments)
                if ($CommandName -eq 'aws' -and $Arguments[0] -eq 's3' -and $Arguments[1] -eq 'ls') {
                    return 'bucket1', 'bucket2'
                }
            } -ParameterFilter { $CommandName -eq 'aws' }
            
            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')
            
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Operation Name Generation' {
        It 'Generates operation name from command and first argument' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName '&' -MockWith { return '{}' } -ParameterFilter { $CommandName -eq 'aws' }
            
            # Mock Invoke-WithWideEvent to capture operation name
            $capturedOperationName = $null
            Mock -CommandName 'Invoke-WithWideEvent' -MockWith {
                param($OperationName, $ScriptBlock)
                $script:capturedOperationName = $OperationName
                return & $ScriptBlock
            }
            
            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')
            
            $capturedOperationName | Should -Be 'aws.s3'
        }
        
        It 'Uses provided operation name' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName '&' -MockWith { return '{}' } -ParameterFilter { $CommandName -eq 'aws' }
            
            $capturedOperationName = $null
            Mock -CommandName 'Invoke-WithWideEvent' -MockWith {
                param($OperationName, $ScriptBlock)
                $script:capturedOperationName = $OperationName
                return & $ScriptBlock
            }
            
            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -OperationName 'custom.operation'
            
            $capturedOperationName | Should -Be 'custom.operation'
        }
    }
    
    Context 'JSON Parsing' {
        It 'Parses JSON output by default' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            $jsonOutput = '{"Buckets":[{"Name":"bucket1"}]}'
            Mock -CommandName '&' -MockWith { return $jsonOutput } -ParameterFilter { $CommandName -eq 'aws' }
            
            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3api', 'list-buckets')
            
            $result | Should -BeOfType [PSCustomObject]
            $result.Buckets | Should -Not -BeNullOrEmpty
        }
        
        It 'Returns raw output when ParseJson is false' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            $textOutput = 'bucket1 bucket2'
            Mock -CommandName '&' -MockWith { return $textOutput } -ParameterFilter { $CommandName -eq 'aws' }
            
            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -ParseJson $false
            
            $result | Should -Be $textOutput
        }
        
        It 'Handles invalid JSON gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            $invalidJson = 'not json'
            Mock -CommandName '&' -MockWith { return $invalidJson } -ParameterFilter { $CommandName -eq 'aws' }
            
            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -ParseJson $true
            
            $result | Should -Be $invalidJson
        }
    }
    
    Context 'Error Handling' {
        It 'Throws error on non-zero exit code by default' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName '&' -MockWith {
                $script:LASTEXITCODE = 1
                return 'Error: Access denied'
            } -ParameterFilter { $CommandName -eq 'aws' }
            
            {
                Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')
            } | Should -Throw
        }
        
        It 'Returns null when ErrorOnNonZeroExit is false' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName '&' -MockWith {
                $script:LASTEXITCODE = 1
                return 'Error'
            } -ParameterFilter { $CommandName -eq 'aws' }
            
            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -ErrorOnNonZeroExit $false
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Context Tracking' {
        It 'Includes command and arguments in context' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName '&' -MockWith { return '{}' } -ParameterFilter { $CommandName -eq 'aws' }
            
            $capturedContext = $null
            Mock -CommandName 'Invoke-WithWideEvent' -MockWith {
                param($OperationName, $Context, $ScriptBlock)
                $script:capturedContext = $Context
                return & $ScriptBlock
            }
            
            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -Context @{ custom = 'value' }
            
            $capturedContext.command | Should -Be 'aws'
            $capturedContext.arguments | Should -Be 's3 ls'
            $capturedContext.custom | Should -Be 'value'
        }
    }
}

Describe 'CloudProviderBase.ps1 - Set-CloudProfile' {
    Context 'Profile Setting' {
        It 'Sets environment variable' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            $result = Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -DisplayName 'AWS profile'
            
            $result | Should -Be $true
            $env:AWS_PROFILE | Should -Be 'production'
        }
        
        It 'Returns false when command is not available' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $result = Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws'
            
            $result | Should -Be $false
        }
        
        It 'Validates setting when ValidateCommand provided' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                param($CommandName, $Arguments)
                if ($Arguments[0] -eq 'sts' -and $Arguments[1] -eq 'get-caller-identity') {
                    return @{ Account = '123456789012' }
                }
                return $null
            }
            
            $result = Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -ValidateCommand 'sts get-caller-identity'
            
            $result | Should -Be $true
        }
    }
}

Describe 'CloudProviderBase.ps1 - Get-CloudResources' {
    Context 'Service/Action Pattern' {
        It 'Builds command arguments from service and action' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            $capturedArguments = $null
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                param($CommandName, $Arguments)
                $script:capturedArguments = $Arguments
                return @{ Instances = @() }
            }
            
            Get-CloudResources -CommandName 'aws' -Service 'ec2' -Action 'describe-instances'
            
            $capturedArguments[0] | Should -Be 'ec2'
            $capturedArguments[1] | Should -Be 'describe-instances'
        }
        
        It 'Generates operation name from service and action' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            $capturedOperationName = $null
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                param($CommandName, $Arguments, $OperationName)
                $script:capturedOperationName = $OperationName
                return @{}
            }
            
            Get-CloudResources -CommandName 'aws' -Service 'ec2' -Action 'describe-instances'
            
            $capturedOperationName | Should -Be 'aws.ec2.describe-instances'
        }
    }
    
    Context 'Direct Arguments Pattern' {
        It 'Uses provided arguments directly' {
            Mock-CommandAvailabilityPester -CommandName 'az' -Available $true
            
            $capturedArguments = $null
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                param($CommandName, $Arguments)
                $script:capturedArguments = $Arguments
                return @()
            }
            
            Get-CloudResources -CommandName 'az' -Arguments @('vm', 'list')
            
            $capturedArguments[0] | Should -Be 'vm'
            $capturedArguments[1] | Should -Be 'list'
        }
    }
    
    Context 'Error Handling' {
        It 'Returns null when neither Service/Action nor Arguments provided' {
            $result = Get-CloudResources -CommandName 'aws'
            
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'CloudProviderBase.ps1 - Test-CloudConnection' {
    Context 'Connection Testing' {
        It 'Tests connection successfully' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                return @{ Account = '123456789012' }
            }
            
            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'
            
            $result | Should -Be $true
        }
        
        It 'Returns false when connection fails' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                return $null
            }
            
            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity')
            
            $result | Should -Be $false
        }
        
        It 'Validates success indicator' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                return @{ Account = '123456789012' }
            }
            
            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'
            
            $result | Should -Be $true
        }
        
        It 'Returns false when success indicator not found' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                return @{ UserId = 'test' }
            }
            
            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'
            
            $result | Should -Be $false
        }
        
        It 'Handles nested success indicators' {
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true
            
            Mock -CommandName 'Invoke-CloudCommand' -MockWith {
                return @{ Response = @{ Account = '123456789012' } }
            }
            
            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Response.Account'
            
            $result | Should -Be $true
        }
    }
}
