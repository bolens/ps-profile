# ===============================================
# profile-security-tools-clamav.tests.ps1
# Unit tests for Invoke-ClamAVScan function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

# Helper function is now in PesterMocks.psm1 module - no local definition needed

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'security-tools.ps1')
    
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

Describe 'security-tools.ps1 - Invoke-ClamAVScan' {
    BeforeEach {
        # Clear command cache to ensure mocks work correctly
        if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
            Remove-TestCachedCommandCacheEntry -Name 'clamscan' -ErrorAction SilentlyContinue
        }
        
        # Clear available command mocks hashtable
        if (Get-Variable -Name '__AvailableCommandMocks' -Scope Global -ErrorAction SilentlyContinue) {
            $global:__AvailableCommandMocks.Clear()
        }
    }
    
    Context 'Invoke-ClamAVScan' {
        It 'Returns null when clamscan is not available' {
            $cmdName = 'clamscan'
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:TestCachedCommandCache.TryRemove($cmdName, [ref]$null)
            }
            if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:AssumedAvailableCommands.TryRemove($cmdName, [ref]$null)
            }
            Remove-Item -Path "Function:\$cmdName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$cmdName" -Force -ErrorAction SilentlyContinue
            
            $originalPath = "Function:\Test-CachedCommand"
            if (-not (Test-Path $originalPath)) {
                $originalPath = "Function:\global:Test-CachedCommand"
            }
            $originalScript = if (Test-Path $originalPath) { (Get-Item $originalPath).ScriptBlock } else { $null }
            
            Mock -CommandName Test-CachedCommand -MockWith {
                param([string]$Name)
                $actualName = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { '' }
                if ($actualName -eq $cmdName) {
                    return $false
                }
                if ($originalScript) {
                    $nameParam = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { '' }
                    return & $originalScript -Name $nameParam
                }
                return $false
            }
            
            Mock -CommandName Get-Command -ParameterFilter {
                $nameToCheck = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { $null }
                $nameToCheck -eq $cmdName
            } -MockWith {
                return $null
            }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when path does not exist' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            $result = Invoke-ClamAVScan -Path 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls clamscan with correct arguments when tool is available' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            # Mock the actual command - no parameter filter to match all calls
            Mock -CommandName 'clamscan' -MockWith { return 'Scan results' }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath
            
            $result | Should -Not -BeNullOrEmpty
            # Verify clamscan was called at least once (it should be called with the path)
            Should -Invoke -CommandName 'clamscan' -Times 1 -Exactly
        }
        
        It 'Includes recursive flag when specified' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            # Capture arguments in a variable
            # When called with & clamscan $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'clamscan' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -Recursive
            
            # Verify clamscan was called with -r flag
            Should -Invoke -CommandName 'clamscan' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '-r'
        }
        
        It 'Creates quarantine directory and includes move flag when specified' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            # Capture arguments in a variable
            # When called with & clamscan $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'clamscan' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $quarantinePath = Join-Path $TestDrive 'quarantine'
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -Quarantine $quarantinePath
            
            # Verify clamscan was called with --move and quarantine path
            Should -Invoke -CommandName 'clamscan' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--move'
            $script:capturedArgs | Should -Contain $quarantinePath
            Test-Path -LiteralPath $quarantinePath | Should -Be $true
        }
        
        It 'Handles ClamAV path not found' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            $result = Invoke-ClamAVScan -Path 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles clamscan execution errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            Mock -CommandName 'clamscan' -MockWith { throw 'Execution failed' }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Tests ClamAV with recursive flag' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            # Capture arguments in a variable
            # When called with & clamscan $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'clamscan' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -Recursive
            
            Should -Invoke -CommandName 'clamscan' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '-r'
        }
        
        It 'Tests ClamAV with both recursive and quarantine' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            
            $quarantinePath = Join-Path $TestDrive 'quarantine'
            New-Item -ItemType Directory -Path $quarantinePath -Force | Out-Null
            
            # Mock Test-Path to return true for the quarantine path when checking if it's a container
            Mock Test-Path { 
                param([string]$LiteralPath, [string]$PathType)
                if ($LiteralPath -eq $script:TestRepoPath) { return $true }
                if ($LiteralPath -eq $quarantinePath -and $PathType -eq 'Container') { return $true }
                if ($LiteralPath -like '*quarantine*') { return $true }
                return $true
            }
            
            # Capture arguments in a variable
            # When called with & clamscan $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'clamscan' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -Recursive -Quarantine $quarantinePath
            
            Should -Invoke -CommandName 'clamscan' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '-r'
            $script:capturedArgs | Should -Contain '--move'
            $script:capturedArgs | Should -Contain $quarantinePath
        }
        
        It 'Tests ClamAV quarantine directory creation' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            Mock Test-Path { 
                if ($LiteralPath -eq $script:TestRepoPath) { return $true }
                if ($LiteralPath -like '*quarantine*') { return $false }
                return $true
            }
            Mock New-Item { return @{ FullName = Join-Path $TestDrive 'quarantine' } }
            Mock -CommandName 'clamscan' -MockWith { return 'Scan results' }
            
            $quarantinePath = Join-Path $TestDrive 'quarantine'
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -Quarantine $quarantinePath
            
            Should -Invoke New-Item -Times 1 -ParameterFilter { $ItemType -eq 'Directory' -and $Path -like '*quarantine*' }
            Should -Invoke -CommandName 'clamscan' -Times 1
        }
        
        It 'Tests clamscan stderr output handling' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            Mock -CommandName 'clamscan' -MockWith { 
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'clamscan' -Times 1
        }
        
        It 'Tests clamscan catch block error handling' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            Mock -CommandName 'clamscan' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('clamscan not found') }
            Mock Write-Error { }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Tests clamscan Write-Error message format' {
            Setup-AvailableCommandMock -CommandName 'clamscan'
            Mock -CommandName 'clamscan' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('clamscan not found') }
            Mock Write-Error { }
            
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1 -ParameterFilter {
                $Message -like '*Failed to run clamscan*'
            }
        }
    }
}

