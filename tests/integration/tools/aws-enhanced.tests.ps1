# ===============================================
# aws-enhanced.tests.ps1
# Integration tests for aws.ps1 enhanced functions
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
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
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'aws' -Available $false
        }

        BeforeAll {
            . (Join-Path $script:ProfileDir 'aws.ps1')
        }

        It 'Get-AwsCredentials handles missing tools gracefully' {
            $output = & { Get-AwsCredentials -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'aws'
        }

        It 'Test-AwsConnection handles missing tools gracefully' {
            $output = & { Test-AwsConnection -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'aws'
        }

        It 'Get-AwsResources handles missing tools gracefully' {
            $output = & {
                Get-AwsResources -Service 'ec2' -Action 'describe-instances' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'aws'
        }

        It 'Export-AwsCredentials handles missing tools gracefully' {
            $output = & { Export-AwsCredentials -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'aws'
        }

        It 'Switch-AwsAccount handles missing tools gracefully' {
            $output = & { Switch-AwsAccount -ProfileName 'test' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'aws'
        }

        It 'Get-AwsCosts handles missing tools gracefully' {
            $output = & { Get-AwsCosts -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'aws'
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

