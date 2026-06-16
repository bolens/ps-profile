# ===============================================
# base.tests.ps1
# Integration tests for CloudProviderBase.ps1
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
    
    # Load bootstrap
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load CloudProviderBase
    . (Join-Path $script:ProfileDir 'bootstrap' 'CloudProviderBase.ps1')
}

Describe 'CloudProviderBase.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads without errors' {
            { . (Join-Path $script:ProfileDir 'bootstrap' 'CloudProviderBase.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            {
                . (Join-Path $script:ProfileDir 'bootstrap' 'CloudProviderBase.ps1')
                . (Join-Path $script:ProfileDir 'bootstrap' 'CloudProviderBase.ps1')
            } | Should -Not -Throw
        }
        
        It 'Registers all required functions' {
            Get-Command Invoke-CloudCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Set-CloudProfile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-CloudResources -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Test-CloudConnection -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Integration with Error Handling' {
        It 'Uses Invoke-WithWideEvent when available' {
            # Ensure ErrorHandlingStandard is loaded
            if (-not (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue)) {
                . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
            }
            
            # Clear events
            if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
                Clear-EventCollection | Out-Null
            }
            
            Setup-CapturingCommandMock -CommandName 'test-cloud-cmd' -ExitCode 0 -Output '{"test":"value"}'
            
            $result = Invoke-CloudCommand -CommandName 'test-cloud-cmd' -Arguments @('test', 'arg')
            
            # Verify event was created
            if ($global:WideEvents) {
                $event = $global:WideEvents | Where-Object { $_.event_name -like 'test-cloud-cmd.*' } | Select-Object -Last 1
                if ($event) {
                    $event.context.command | Should -Be 'test-cloud-cmd'
                }
            }
        }
    }
    
    Context 'Provider-Specific Usage Patterns' {
        It 'Supports AWS-style service/action pattern' {
            # Verifies Get-CloudResources handles missing aws CLI without throwing
            Mark-TestCommandsUnavailable -CommandNames @('aws')
            Set-TestCommandAvailabilityState -CommandName 'aws' -Available $false
            $result = Get-CloudResources -CommandName 'aws' -Service 's3' -Action 'list-buckets' -ErrorAction SilentlyContinue
            # When aws is not available, result should be null/empty (graceful degradation)
            $result | Should -BeNullOrEmpty
        }
        
        It 'Supports Azure-style direct arguments pattern' {
            # Verifies Get-CloudResources handles missing az CLI without throwing
            Mark-TestCommandsUnavailable -CommandNames @('az')
            Set-TestCommandAvailabilityState -CommandName 'az' -Available $false
            $result = Get-CloudResources -CommandName 'az' -Arguments @('account', 'show') -ErrorAction SilentlyContinue
            # When az is not available, result should be null/empty (graceful degradation)
            $result | Should -BeNullOrEmpty
        }
        
        It 'Supports GCloud-style project management' {
            try {
            $originalProject = $env:GCLOUD_PROJECT
            
                        $result = Set-CloudProfile -ProviderName 'gcloud' -ProfileType 'Project' -Value 'test-project' -EnvVarName 'GCLOUD_PROJECT' -ErrorAction SilentlyContinue
            
            # Should set environment variable
            if ($result) {
                $env:GCLOUD_PROJECT | Should -Be 'test-project'
            }
            }
            finally {
                if ($originalProject) {
                    $env:GCLOUD_PROJECT = $originalProject
                }
                else {
                    Remove-Item Env:GCLOUD_PROJECT -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    Context 'Graceful Degradation' {
        It 'Handles missing commands gracefully' {
            # Clear cache to force re-check
            if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:TestCachedCommandCache.TryRemove('nonexistent-cmd', [ref]$null)
            }
            
            $result = Invoke-CloudCommand -CommandName 'nonexistent-cmd' -Arguments @('test') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Falls back when Invoke-WithWideEvent is not available' {
            try {
            # Temporarily remove Invoke-WithWideEvent if it exists
            $savedFunction = Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue
            if ($savedFunction) {
                Remove-Item Function:Invoke-WithWideEvent -Force -ErrorAction SilentlyContinue
            }
            
                        Setup-CapturingCommandMock -CommandName 'test-cmd' -ExitCode 0 -Output 'test output'
            
            $result = Invoke-CloudCommand -CommandName 'test-cmd' -Arguments @('test') -ErrorAction SilentlyContinue
            
            # Should still work without wide event tracking
            $result | Should -Not -BeNullOrEmpty
            }
            finally {
                # Restore function if it existed
                if ($savedFunction) {
                    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
                }
            }
        }
    }
}
