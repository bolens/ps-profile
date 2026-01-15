# ===============================================
# profile-security-tools-helpers.tests.ps1
# Unit tests for helper functions (Get-ToolInstallHint, Write-MissingToolWarning)
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'security-tools.ps1')
    
    # Ensure Get-ToolInstallHint is available (it's imported by security-tools.ps1)
    # If it's not available, import it manually
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
        if (Test-Path -LiteralPath $commandModulePath) {
            Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
        }
    }
    
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

Describe 'security-tools.ps1 - Helper Functions' {
    Context 'Get-ToolInstallHint Helper' {
        BeforeEach {
            # Create a function mock for Import-Requirements so Get-Command can find it
            <#
            .SYNOPSIS
                Performs operations related to Import-Requirements.
            
            .DESCRIPTION
                Performs operations related to Import-Requirements.
            
            .PARAMETER RepoRoot
                The RepoRoot parameter.
            
            .PARAMETER UseCache
                The UseCache parameter.
            
            .OUTPUTS
                object
            #>
            function Import-Requirements {
                param([string]$RepoRoot, [switch]$UseCache)
                return $null
            }
            
            # Mock Get-Command to return Import-Requirements function when requested
            Mock Get-Command -ParameterFilter { $Name -eq 'Import-Requirements' } -MockWith {
                return @{ Name = 'Import-Requirements' }
            }
        }
        
        It 'Returns default install hint when requirements not loaded' {
            # Mock Import-Requirements to return null (requirements not loaded)
            Mock Import-Requirements { return $null }
            
            # Get-ToolInstallHint should return default when requirements are null
            $hint = Get-ToolInstallHint -ToolName 'gitleaks'
            $hint | Should -Match 'Install with: scoop install gitleaks'
        }
        
        It 'Returns default when ExternalTools is null' {
            # Mock Import-Requirements to return requirements with null ExternalTools
            Mock Import-Requirements { return @{} }
            
            $hint = Get-ToolInstallHint -ToolName 'gitleaks'
            $hint | Should -Match 'Install with: scoop install gitleaks'
        }
        
        It 'Returns default when tool not in ExternalTools' {
            # Mock Import-Requirements to return requirements with empty ExternalTools
            Mock Import-Requirements { return @{ ExternalTools = @{} } }
            
            $hint = Get-ToolInstallHint -ToolName 'gitleaks'
            $hint | Should -Match 'Install with: scoop install gitleaks'
        }
        
        It 'Returns install hint from requirements when Resolve-InstallCommand available' {
            # Mock Import-Requirements to return requirements with tool definition
            Mock Import-Requirements {
                return @{
                    ExternalTools = @{
                        'gitleaks' = @{
                            InstallCommand = @{
                                Windows = 'scoop install gitleaks'
                                Linux   = 'apt install gitleaks'
                                MacOS   = 'brew install gitleaks'
                            }
                        }
                    }
                }
            }
            
            # Mock Resolve-InstallCommand directly (it's already available from the module)
            # Get-Command will find it from the module, and our mock will intercept calls
            # Use explicit parameters to match the function signature
            Mock Resolve-InstallCommand -MockWith {
                param([object]$InstallCommand, [string]$PackageName)
                return 'scoop install gitleaks'
            }
            
            $hint = Get-ToolInstallHint -ToolName 'gitleaks'
            $hint | Should -Match 'Install with: scoop install gitleaks'
            Should -Invoke Resolve-InstallCommand -Times 1
        }
        
        It 'Falls back to manual platform resolution when Resolve-InstallCommand unavailable' {
            # Mock Import-Requirements to return requirements with tool definition
            Mock Import-Requirements {
                return @{
                    ExternalTools = @{
                        'trufflehog' = @{
                            InstallCommand = @{
                                Windows = 'scoop install trufflehog'
                                Linux   = 'apt install trufflehog'
                            }
                        }
                    }
                }
            }
            
            # Remove Resolve-InstallCommand if it exists
            if (Get-Command Resolve-InstallCommand -ErrorAction SilentlyContinue) {
                Remove-Item Function:\Resolve-InstallCommand -ErrorAction SilentlyContinue
            }
            
            $hint = Get-ToolInstallHint -ToolName 'trufflehog'
            $hint | Should -Match 'Install with:'
        }
        
        It 'Returns default when InstallCommand is null' {
            # Mock Import-Requirements to return requirements with null InstallCommand
            Mock Import-Requirements {
                return @{
                    ExternalTools = @{
                        'yara' = @{
                            InstallCommand = $null
                        }
                    }
                }
            }
            
            $hint = Get-ToolInstallHint -ToolName 'yara'
            $hint | Should -Match 'Install with: scoop install yara'
        }
        
        It 'Returns default when resolved install command is null' {
            # Mock Import-Requirements to return requirements with tool definition
            Mock Import-Requirements {
                return @{
                    ExternalTools = @{
                        'osv-scanner' = @{
                            InstallCommand = @{
                                Windows = 'scoop install osv-scanner'
                            }
                        }
                    }
                }
            }
            
            # CRITICAL: Remove Resolve-InstallCommand from function provider if it exists
            # Get-Command checks function provider first, so we must remove it
            Remove-Item -Path "Function:\Resolve-InstallCommand" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:Resolve-InstallCommand" -Force -ErrorAction SilentlyContinue
            
            # Mock Get-Command to return Resolve-InstallCommand so Get-ToolInstallHint will use it
            # Use simple ParameterFilter pattern from fragment tests
            Mock Get-Command -ParameterFilter { $Name -eq 'Resolve-InstallCommand' } -MockWith {
                return @{ Name = 'Resolve-InstallCommand' }
            }
            
            Mock Resolve-InstallCommand { return $null }
            
            $hint = Get-ToolInstallHint -ToolName 'osv-scanner'
            $hint | Should -Match 'Install with: scoop install osv-scanner'
        }
        
        It 'Handles string InstallCommand' {
            # Mock Import-Requirements to return requirements with string InstallCommand
            Mock Import-Requirements {
                return @{
                    ExternalTools = @{
                        'clamav' = @{
                            InstallCommand = 'scoop install clamav'
                        }
                    }
                }
            }
            
            # CRITICAL: Remove Resolve-InstallCommand from function provider if it exists
            # Get-Command checks function provider first, so we must remove it
            Remove-Item -Path "Function:\Resolve-InstallCommand" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:Resolve-InstallCommand" -Force -ErrorAction SilentlyContinue
            
            # Mock Get-Command to return Resolve-InstallCommand so Get-ToolInstallHint will use it
            # Use simple ParameterFilter pattern from fragment tests
            Mock Get-Command -ParameterFilter { $Name -eq 'Resolve-InstallCommand' } -MockWith {
                return @{ Name = 'Resolve-InstallCommand' }
            }
            
            Mock Resolve-InstallCommand { return 'scoop install clamav' }
            
            $hint = Get-ToolInstallHint -ToolName 'clamav'
            $hint | Should -Match 'Install with: scoop install clamav'
        }
        
        It 'Handles Get-RepoRoot failure in Get-ToolInstallHint path' {
            Mock Test-CachedCommand { return $false } -ParameterFilter { $CommandName -eq 'gitleaks' }
            Mock Get-RepoRoot { throw 'Get-RepoRoot failed' } -ParameterFilter { $ScriptPath -eq $PSScriptRoot }
            Mock Get-ToolInstallHint { return 'Install with: scoop install gitleaks' }
            Mock Write-MissingToolWarning { }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
            # Should still work with fallback
            Should -Invoke Write-MissingToolWarning -Times 1
        }
        
        It 'Handles Get-ToolInstallHint returning null' {
            Mock Test-CachedCommand { return $false } -ParameterFilter { $CommandName -eq 'gitleaks' }
            Mock Get-ToolInstallHint { return $null }
            Mock Write-MissingToolWarning { }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
            # Should still call Write-MissingToolWarning
            Should -Invoke Write-MissingToolWarning -Times 1
        }
        
        It 'Tests module import path when Get-ToolInstallHint not available' {
            # Remove Get-ToolInstallHint if it exists
            Remove-Module Command -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-ToolInstallHint -ErrorAction SilentlyContinue
            
            # Reload fragment to test import logic
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                Mock Get-Command { 
                    if ($Name -eq 'Get-ToolInstallHint') { return $null }
                    return @{ Name = $Name }
                }
                Mock Test-Path { return $true } -ParameterFilter { $LiteralPath -like '*Command.psm1' }
                Mock Import-Module { }
                
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
                
                # Should attempt to import Command module
                Should -Invoke Import-Module -Times 1 -ParameterFilter { $Name -like '*Command.psm1' }
            }
        }
        
        It 'Tests fallback path when Get-RepoRoot not available during module import' {
            Remove-Module Command -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-ToolInstallHint -ErrorAction SilentlyContinue
            
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                Mock Get-Command { 
                    if ($Name -eq 'Get-ToolInstallHint') { return $null }
                    if ($Name -eq 'Get-RepoRoot') { return $null }
                    return @{ Name = $Name }
                }
                Mock Test-Path { return $true } -ParameterFilter { $LiteralPath -like '*Command.psm1' }
                Mock Import-Module { }
                
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
                
                # Should still attempt import using fallback path calculation
                Should -Invoke Import-Module -Times 1
            }
        }
        
        It 'Tests when repoRoot is null during module import' {
            Remove-Module Command -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-ToolInstallHint -ErrorAction SilentlyContinue
            
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                Mock Get-Command { 
                    if ($Name -eq 'Get-ToolInstallHint') { return $null }
                    if ($Name -eq 'Get-RepoRoot') { return @{ Name = 'Get-RepoRoot' } }
                    return @{ Name = $Name }
                }
                Mock Get-RepoRoot { return $null }
                
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
                
                # Fragment should still load even if module import fails
                Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Tests when Command module path does not exist' {
            Remove-Module Command -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-ToolInstallHint -ErrorAction SilentlyContinue
            
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                Mock Get-Command { 
                    if ($Name -eq 'Get-ToolInstallHint') { return $null }
                    return @{ Name = $Name }
                }
                Mock Test-Path { return $false } -ParameterFilter { $LiteralPath -like '*Command.psm1' }
                
                . $script:SecurityToolsPath -ErrorAction SilentlyContinue
                
                # Fragment should still load
                Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context 'Write-MissingToolWarning Integration' {
        It 'Uses Write-MissingToolWarning when tool is missing' {
            Mock Test-CachedCommand { return $false } -ParameterFilter { $CommandName -eq 'gitleaks' }
            Mock Write-MissingToolWarning { }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
            Should -Invoke Write-MissingToolWarning -Times 1 -ParameterFilter { 
                $Tool -eq 'gitleaks' -and 
                $InstallHint -match 'Install with:'
            }
        }
        
        It 'Falls back to Write-Warning when Write-MissingToolWarning unavailable' {
            # Remove Write-MissingToolWarning function if it exists (like fragment tests do)
            Remove-Item -Path "Function:\Write-MissingToolWarning" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:Write-MissingToolWarning" -Force -ErrorAction SilentlyContinue
            
            # Mock Get-Command to return null for Write-MissingToolWarning (simple pattern from fragment tests)
            Mock Get-Command -ParameterFilter { $Name -eq 'Write-MissingToolWarning' } -MockWith {
                return $null
            }
            
            Mock Test-CachedCommand { return $false } -ParameterFilter { $CommandName -eq 'trufflehog' }
            Mock Write-Warning { }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            # Should have used Write-Warning as fallback
            Should -Invoke Write-Warning -Times 1
            $result | Should -BeNullOrEmpty
        }
    }
}

