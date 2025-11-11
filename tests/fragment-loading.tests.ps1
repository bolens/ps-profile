Describe 'Fragment Loading Failure Scenarios' {
    BeforeAll {
        $script:ProfileDir = Join-Path $PSScriptRoot '..\profile.d'
        $script:ProfilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
        
        # Helper to create a temporary fragment with specific content
        function script:New-TestFragment {
            param(
                [string]$Name,
                [string]$Content
            )
            
            $fragmentPath = Join-Path $script:ProfileDir $Name
            Set-Content -Path $fragmentPath -Value $Content -Encoding UTF8
            return $fragmentPath
        }
        
        # Helper to remove test fragment
        function script:Remove-TestFragment {
            param([string]$Name)
            $fragmentPath = Join-Path $script:ProfileDir $Name
            Remove-Item -Path $fragmentPath -Force -ErrorAction SilentlyContinue
        }
    }
    
    AfterEach {
        # Clean up any test fragments
        Get-ChildItem -Path $script:ProfileDir -Filter '99-test-*.ps1' -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    Context 'Fragment Loading Failures' {
        It 'handles fragment with syntax error gracefully' {
            $fragmentName = '99-test-syntax-error.ps1'
            $badContent = @'
function Test-BadFunction {
    # Missing closing brace
    Write-Output 'test'
'@
            
            New-TestFragment -Name $fragmentName -Content $badContent
            
            # Profile should still load despite syntax error in one fragment
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }
        
        It 'handles fragment that throws exception' {
            $fragmentName = '99-test-exception.ps1'
            $badContent = @'
throw "Test exception from fragment"
'@
            
            New-TestFragment -Name $fragmentName -Content $badContent
            
            # Profile should handle exception and continue loading
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }
        
        It 'handles fragment with missing dependency gracefully' {
            $fragmentName = '99-test-missing-dep.ps1'
            $badContent = @'
# Try to use a function that doesn't exist
$result = NonExistent-Function -Parameter 'test'
'@
            
            New-TestFragment -Name $fragmentName -Content $badContent
            
            # Profile should handle missing dependency error
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }
        
        It 'continues loading other fragments after failure' {
            $fragmentName1 = '99-test-fail1.ps1'
            $fragmentName2 = '99-test-success.ps1'
            
            $failContent = @'
throw "Fragment 1 fails"
'@
            $successContent = @'
$global:TestFragmentLoaded = $true
'@
            
            New-TestFragment -Name $fragmentName1 -Content $failContent
            New-TestFragment -Name $fragmentName2 -Content $successContent
            
            # Clear the test variable
            $global:TestFragmentLoaded = $false
            
            # Profile should continue loading despite first fragment failure
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Second fragment should have loaded
            $global:TestFragmentLoaded | Should -Be $true
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName1
            Remove-TestFragment -Name $fragmentName2
            $global:TestFragmentLoaded = $false
        }
    }
    
    Context 'Fragment Idempotency Edge Cases' {
        It 'handles fragment that modifies global state multiple times' {
            $fragmentName = '99-test-state-mod.ps1'
            $content = @'
if (-not $global:FragmentLoadCount) {
    $global:FragmentLoadCount = 0
}
$global:FragmentLoadCount++
'@
            
            New-TestFragment -Name $fragmentName -Content $content
            
            # Clear state
            $global:FragmentLoadCount = 0
            
            # Load profile multiple times
            . $script:ProfilePath
            $firstLoad = $global:FragmentLoadCount
            
            . $script:ProfilePath
            $secondLoad = $global:FragmentLoadCount
            
            # Fragment should be idempotent (or at least handle multiple loads)
            # Exact behavior depends on fragment design, but shouldn't crash
            $secondLoad | Should -BeGreaterThan $firstLoad
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
            $global:FragmentLoadCount = $null
        }
        
        It 'handles fragment that defines functions multiple times' {
            $fragmentName = '99-test-function-def.ps1'
            $content = @'
function Test-IdempotentFunction {
    Write-Output 'loaded'
}
'@
            
            New-TestFragment -Name $fragmentName -Content $content
            
            # Load profile multiple times
            . $script:ProfilePath
            $firstExists = Get-Command Test-IdempotentFunction -ErrorAction SilentlyContinue
            
            . $script:ProfilePath
            $secondExists = Get-Command Test-IdempotentFunction -ErrorAction SilentlyContinue
            
            # Function should exist after both loads (idempotent)
            $firstExists | Should -Not -BeNullOrEmpty
            $secondExists | Should -Not -BeNullOrEmpty
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
            Remove-Item Function:\Test-IdempotentFunction -ErrorAction SilentlyContinue
        }
    }
    
    Context 'Error Recovery' {
        It 'recovers from fragment loading error and allows subsequent loads' {
            $fragmentName = '99-test-recovery.ps1'
            $badContent = @'
throw "Recovery test error"
'@
            
            New-TestFragment -Name $fragmentName -Content $badContent
            
            # First load with error
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Second load should also work (recovery)
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }
        
        It 'handles missing profile.d directory' {
            # This test verifies the profile handles missing directory
            # Note: Actual behavior depends on profile implementation
            $profileContent = Get-Content $script:ProfilePath -Raw
            
            # Profile should check for directory existence
            $profileContent | Should -Match 'Test-Path.*profile\.d'
        }
        
        It 'handles corrupted fragment configuration file' {
            $configPath = Join-Path (Split-Path $script:ProfilePath -Parent) '.profile-fragments.json'
            $originalContent = $null
            
            if (Test-Path $configPath) {
                $originalContent = Get-Content $configPath -Raw
            }
            
            try {
                # Create invalid JSON
                Set-Content -Path $configPath -Value '{ invalid json }' -Encoding UTF8
                
                # Profile should handle corrupted config gracefully
                { . $script:ProfilePath } | Should -Not -Throw
            }
            finally {
                # Restore original config
                if ($originalContent) {
                    Set-Content -Path $configPath -Value $originalContent -Encoding UTF8
                }
                else {
                    Remove-Item $configPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    Context 'Missing Dependencies' {
        It 'handles fragment referencing non-existent command' {
            $fragmentName = '99-test-missing-cmd.ps1'
            $content = @'
# Try to use a command that doesn't exist
$result = Get-NonExistentCommand -ErrorAction SilentlyContinue
'@
            
            New-TestFragment -Name $fragmentName -Content $content
            
            # Profile should handle missing command gracefully
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }
        
        It 'handles fragment referencing non-existent module' {
            $fragmentName = '99-test-missing-module.ps1'
            $content = @'
Import-Module NonExistentModule -ErrorAction SilentlyContinue
'@
            
            New-TestFragment -Name $fragmentName -Content $content
            
            # Profile should handle missing module gracefully
            { . $script:ProfilePath } | Should -Not -Throw
            
            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }
    }
}

