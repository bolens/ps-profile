# ===============================================
# profile-security-tools-trufflehog.tests.ps1
# Unit tests for Invoke-TruffleHogScan function
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

Describe 'security-tools.ps1 - Invoke-TruffleHogScan' {
    Context 'Invoke-TruffleHogScan' {
        It 'Returns null when trufflehog is not available' {
            # Helper function to set up mocks for unavailable commands
            $cmdName = 'trufflehog'
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
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when path does not exist' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            
            $result = Invoke-TruffleHogScan -Path 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls trufflehog with correct arguments when tool is available' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'trufflehog' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'trufflehog' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain 'filesystem'
            $script:capturedArgs | Should -Contain $script:TestRepoPath
            $script:capturedArgs | Should -Contain '--json'
        }
        
        It 'Uses default path when not specified' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-TruffleHogScan
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Handles trufflehog execution errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { throw 'Execution failed' }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Validates OutputFormat parameter' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            
            { Invoke-TruffleHogScan -Path $script:TestRepoPath -OutputFormat 'invalid' } | 
            Should -Throw
        }
        
        It 'Tests trufflehog with yaml format' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'trufflehog' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -OutputFormat 'yaml'
            
            Should -Invoke -CommandName 'trufflehog' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '--yaml'
        }
        
        It 'Handles empty string path' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-TruffleHogScan -Path ''
                # Should use current directory as default
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Handles trufflehog path not found' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            
            $result = Invoke-TruffleHogScan -Path 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Uses default path when trufflehog path is whitespace' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-TruffleHogScan -Path '   '
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Handles multiple pipeline inputs' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { return 'Scan results' }
            
            $paths = @($script:TestRepoPath, $script:TestFile)
            $results = $paths | Invoke-TruffleHogScan
            
            # Should process each path
            Should -Invoke -CommandName 'trufflehog' -Times 2
        }
        
        It 'Tests trufflehog stderr output handling' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock trufflehog { 
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'trufflehog' -Times 1
        }
        
        It 'Tests trufflehog catch block error handling' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('trufflehog not found') }
            Mock Write-Error { }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Tests trufflehog Write-Error message format' {
            Setup-AvailableCommandMock -CommandName 'trufflehog'
            Mock -CommandName 'trufflehog' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('trufflehog not found') }
            Mock Write-Error { }
            
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1 -ParameterFilter {
                $Message -like '*Failed to run trufflehog*'
            }
        }
    }
}

