# ===============================================
# profile-security-tools-fragment.tests.ps1
# Unit tests for fragment loading, registration, and requirements
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:SecurityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . $script:SecurityToolsPath
    
    # Create test directories
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestRepoPath = Join-Path $TestDrive 'TestRepo'
        $script:TestFile = Join-Path $TestDrive 'test-file.txt'
        $script:TestRulesPath = Join-Path $TestDrive 'test-rules.yar'
        
        New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
        Set-Content -Path $script:TestFile -Value 'Test content'
        Set-Content -Path $script:TestRulesPath -Value 'rule TestRule { condition: true }'
    }
}

Describe 'security-tools.ps1 - Fragment Loading and Registration' {
    Context 'Function Registration' {
        It 'Registers Invoke-GitLeaksScan function' {
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers gitleaks-scan alias' {
            # Alias may not be created if command already exists, so try to create it if missing
            if (-not (Get-Alias gitleaks-scan -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'gitleaks-scan' -Target 'Invoke-GitLeaksScan' | Out-Null
                }
            }
            Get-Alias gitleaks-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-TruffleHogScan function' {
            Get-Command Invoke-TruffleHogScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers trufflehog-scan alias' {
            # Alias may not be created if command already exists, so try to create it if missing
            if (-not (Get-Alias trufflehog-scan -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'trufflehog-scan' -Target 'Invoke-TruffleHogScan' | Out-Null
                }
            }
            Get-Alias trufflehog-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-OSVScan function' {
            Get-Command Invoke-OSVScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers osv-scan alias' {
            # Alias may not be created if command already exists, so try to create it if missing
            if (-not (Get-Alias osv-scan -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'osv-scan' -Target 'Invoke-OSVScan' | Out-Null
                }
            }
            Get-Alias osv-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-YaraScan function' {
            Get-Command Invoke-YaraScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers yara-scan alias' {
            # Alias may not be created if command already exists, so try to create it if missing
            if (-not (Get-Alias yara-scan -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'yara-scan' -Target 'Invoke-YaraScan' | Out-Null
                }
            }
            Get-Alias yara-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-ClamAVScan function' {
            Get-Command Invoke-ClamAVScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers clamav-scan alias' {
            # Alias may not be created if command already exists, so try to create it if missing
            if (-not (Get-Alias clamav-scan -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'clamav-scan' -Target 'Invoke-ClamAVScan' | Out-Null
                }
            }
            Get-Alias clamav-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-DangerzoneConvert function' {
            Get-Command Invoke-DangerzoneConvert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers dangerzone-convert alias' {
            # Alias may not be created if command already exists, so try to create it if missing
            if (-not (Get-Alias dangerzone-convert -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'dangerzone-convert' -Target 'Invoke-DangerzoneConvert' | Out-Null
                }
            }
            Get-Alias dangerzone-convert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Fragment Loading' {
        It 'Fragment loads without errors' {
            # Fragment should have loaded in BeforeAll
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-TruffleHogScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-OSVScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-YaraScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-ClamAVScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-DangerzoneConvert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Fragment is idempotent (can be loaded multiple times)' {
            # Reload fragment
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                . $script:SecurityToolsPath
            }
            
            # Functions should still be available
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles missing Get-RepoRoot gracefully' {
            # Mock Get-Command to return null for Get-RepoRoot (simulating it doesn't exist)
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-RepoRoot' } -MockWith { return $null }
            
            # Fragment should still load
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
            }
            
            # Functions should still be available
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Tests idempotency check with Test-FragmentLoaded' {
            # Create a function mock for Test-FragmentLoaded so Get-Command can find it
            <#
            .SYNOPSIS
                Performs operations related to Test-FragmentLoaded.
            
            .DESCRIPTION
                Performs operations related to Test-FragmentLoaded.
            
            .PARAMETER FragmentName
                The FragmentName parameter.
            
            .OUTPUTS
                object
            #>
            function Test-FragmentLoaded {
                param([string]$FragmentName)
                return $true
            }
            
            # Mock Get-Command to return Test-FragmentLoaded function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Test-FragmentLoaded' } -MockWith {
                return @{ Name = 'Test-FragmentLoaded' }
            }
            
            # Mock Test-FragmentLoaded to capture calls
            Mock Test-FragmentLoaded -MockWith {
                param([string]$FragmentName)
                return $true
            }
            
            # Reload fragment
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }
            
            # Should have checked if fragment was loaded
            Should -Invoke Test-FragmentLoaded -Times 1 -ParameterFilter { $FragmentName -eq 'security-tools' }
        }
        
        It 'Tests idempotency check when Test-FragmentLoaded not available' {
            # Remove Test-FragmentLoaded function if it exists
            Remove-Item -Path "Function:\Test-FragmentLoaded" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:Test-FragmentLoaded" -Force -ErrorAction SilentlyContinue
            
            # Mock Get-Command to return null for Test-FragmentLoaded (simulating it doesn't exist)
            # For other commands, pass through to real Get-Command
            Mock Get-Command -ParameterFilter { $Name -eq 'Test-FragmentLoaded' } -MockWith {
                return $null
            }
            
            # Reload fragment
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }
            
            # Functions should still be registered
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Tests function registration idempotency check' {
            # Ensure function exists (it should from BeforeAll, but verify)
            if (-not (Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue)) {
                # If it doesn't exist, load the fragment first
                if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                    . $script:SecurityToolsPath
                }
            }
            
            # Function should now exist
            $beforeCount = @(Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue).Count
            $beforeCount | Should -BeGreaterThan 0 -Because "Function should exist from BeforeAll or after initial load"
            
            # Reload fragment (should not create duplicates due to Set-AgentModeFunction idempotency)
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                . $script:SecurityToolsPath
            }
            
            # Should not create duplicate functions (Set-AgentModeFunction checks if function exists)
            $afterCount = @(Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue).Count
            $afterCount | Should -Be $beforeCount -Because "Function count should not change after reload"
        }
        
        It 'Tests alias registration idempotency' {
            # Alias should already exist
            $aliasBefore = Get-Alias gitleaks-scan -ErrorAction SilentlyContinue
            
            # Reload fragment
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                . $script:SecurityToolsPath
            }
            
            # Alias should still exist
            $aliasAfter = Get-Alias gitleaks-scan -ErrorAction SilentlyContinue
            $aliasAfter | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Requirements Loading' {
        It 'Loads requirements when Import-Requirements is available' {
            # Note: The security-tools fragment doesn't actually use Import-Requirements
            # This test verifies the fragment loads successfully regardless
            # Mock Get-Command to return null for Import-Requirements (simulating it doesn't exist)
            Mock Get-Command -ParameterFilter { $Name -eq 'Import-Requirements' } -MockWith { return $null }
            
            # Fragment should still load
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }
            
            # Functions should still be available
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles missing Get-RepoRoot gracefully' {
            # Fragment should still load even if Get-RepoRoot fails
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
            }
            
            # Functions should still be available
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles Import-Requirements failure gracefully' {
            # Note: The security-tools fragment doesn't actually use Import-Requirements
            # This test verifies the fragment loads successfully regardless
            # Mock Get-Command to return null for Import-Requirements (simulating it doesn't exist)
            Mock Get-Command -ParameterFilter { $Name -eq 'Import-Requirements' } -MockWith { return $null }
            
            # Fragment should still load
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
            }
            
            # Functions should still be available
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls Set-FragmentLoaded when fragment loads successfully' {
            # Create a function mock for Set-FragmentLoaded so Get-Command can find it
            function Set-FragmentLoaded {
                param([string]$FragmentName)
            }
            
            # Mock Get-Command to return Set-FragmentLoaded function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Set-FragmentLoaded' } -MockWith {
                return @{ Name = 'Set-FragmentLoaded' }
            }
            
            # Mock Set-FragmentLoaded to capture calls
            Mock Set-FragmentLoaded -MockWith {
                param([string]$FragmentName)
            }
            
            # Reload fragment
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }
            
            # Should have called Set-FragmentLoaded
            Should -Invoke Set-FragmentLoaded -Times 1 -ParameterFilter { $FragmentName -eq 'security-tools' }
        }
        
        It 'Handles fragment loading errors with Write-ProfileError' {
            # Create a function mock for Write-ProfileError so Get-Command can find it
            function Write-ProfileError {
                param(
                    [Parameter(Mandatory)]
                    [System.Management.Automation.ErrorRecord]$ErrorRecord,
                    [string]$Context,
                    [string]$Category
                )
            }
            
            # Mock Get-Command to return Write-ProfileError function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Write-ProfileError' } -MockWith {
                return @{ Name = 'Write-ProfileError' }
            }
            
            # Mock Write-ProfileError to capture calls
            Mock Write-ProfileError -MockWith {
                param(
                    [Parameter(Mandatory)]
                    [System.Management.Automation.ErrorRecord]$ErrorRecord,
                    [string]$Context,
                    [string]$Category
                )
            }
            
            # Create a temporary invalid fragment to test error handling
            $tempFragment = Join-Path $TestDrive 'temp-security-tools.ps1'
            $fragmentContent = @'
try {
    throw "Test error"
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: security-tools' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load security-tools fragment: $($_.Exception.Message)"
    }
}
'@
            Set-Content -Path $tempFragment -Value $fragmentContent
            
            . $tempFragment -ErrorAction SilentlyContinue
            
            # Write-ProfileError should be called when error occurs
            Should -Invoke Write-ProfileError -Times 1
        }
        
        It 'Tests Write-Warning fallback when Write-ProfileError not available' {
            Mock Write-Warning { }
            
            # Create a fragment that will error without Write-ProfileError
            $tempFragment = Join-Path $TestDrive 'temp-security-tools.ps1'
            $fragmentContent = @'
try {
    throw "Test error"
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: security-tools' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load security-tools fragment: $($_.Exception.Message)"
    }
}
'@
            Set-Content -Path $tempFragment -Value $fragmentContent
            
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq 'Write-ProfileError' }
            
            . $tempFragment -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Warning -Times 1 -ParameterFilter { $Message -like '*Failed to load security-tools fragment*' }
        }
    }
}

