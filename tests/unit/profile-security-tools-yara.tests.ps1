# ===============================================
# profile-security-tools-yara.tests.ps1
# Unit tests for Invoke-YaraScan function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

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

Describe 'security-tools.ps1 - Invoke-YaraScan' {
    BeforeEach {
        # Clear command cache to ensure mocks work correctly
        if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
            Remove-TestCachedCommandCacheEntry -Name 'yara' -ErrorAction SilentlyContinue
        }
    }
    
    Context 'Invoke-YaraScan' {
        It 'Returns null when yara is not available' {
            $cmdName = 'yara'
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
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when file path does not exist' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            $result = Invoke-YaraScan -FilePath 'C:\NonExistent\File.txt' -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when rules path does not exist' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath 'C:\NonExistent\Rules.yar' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls yara with correct arguments when tool is available' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'yara' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'yara' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain $script:TestRulesPath
            $script:capturedArgs | Should -Contain $script:TestFile
        }
        
        It 'Includes recursive flag when specified' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'yara' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-YaraScan -FilePath $script:TestRepoPath -RulesPath $script:TestRulesPath -Recursive
            
            Should -Invoke -CommandName 'yara' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '-r'
        }
        
        It 'Handles YARA file path not found' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            $result = Invoke-YaraScan -FilePath 'C:\NonExistent\File.exe' -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles YARA rules path not found' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath 'C:\NonExistent\Rules.yar' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles yara execution errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'yara'
            Mock -CommandName 'yara' -MockWith { throw 'Execution failed' }
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Tests yara with recursive flag' {
            Setup-AvailableCommandMock -CommandName 'yara'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'yara' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -Recursive
            
            Should -Invoke -CommandName 'yara' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '-r'
        }
        
        It 'Tests yara stderr output handling' {
            Setup-AvailableCommandMock -CommandName 'yara'
            Mock -CommandName 'yara' { 
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'yara' -Times 1
        }
        
        It 'Tests yara catch block error handling' {
            Setup-AvailableCommandMock -CommandName 'yara'
            Mock -CommandName 'yara' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('yara not found') }
            Mock Write-Error { }
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Tests yara Write-Error message format' {
            Setup-AvailableCommandMock -CommandName 'yara'
            Mock -CommandName 'yara' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('yara not found') }
            Mock Write-Error { }
            
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1 -ParameterFilter {
                $Message -like '*Failed to run yara*'
            }
        }
    }
}

