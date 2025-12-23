# ===============================================
# profile-security-tools-osv.tests.ps1
# Unit tests for Invoke-OSVScan function
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

Describe 'security-tools.ps1 - Invoke-OSVScan' {
    BeforeEach {
        # Clear command cache to ensure mocks work correctly
        if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
            Remove-TestCachedCommandCacheEntry -Name 'osv-scanner' -ErrorAction SilentlyContinue
        }
    }
    
    Context 'Invoke-OSVScan' {
        It 'Returns null when osv-scanner is not available' {
            $cmdName = 'osv-scanner'
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
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when path does not exist' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            $result = Invoke-OSVScan -Path 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls osv-scanner with correct arguments when tool is available' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'osv-scanner' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat 'json'
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'osv-scanner' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '--format'
            $script:capturedArgs | Should -Contain 'json'
            $script:capturedArgs | Should -Contain $script:TestRepoPath
        }
        
        It 'Uses default path and format when not specified' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'osv-scanner' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-OSVScan
                $result | Should -Not -BeNullOrEmpty
                Should -Invoke -CommandName 'osv-scanner' -Times 1 -Exactly
                if ($null -eq $script:capturedArgs) {
                    throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
                }
                $script:capturedArgs | Should -Contain '--format'
                $script:capturedArgs | Should -Contain 'table'
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Supports different output formats' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            # Capture arguments for each call in a list
            $script:capturedArgsList = @()
            Mock -CommandName 'osv-scanner' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Flatten arguments array - when called with & osv-scanner $args, PowerShell expands the array
                $flatArgs = @()
                foreach ($arg in $Arguments) {
                    if ($arg -is [array]) {
                        $flatArgs += $arg
                    }
                    else {
                        $flatArgs += $arg
                    }
                }
                $script:capturedArgsList += ,@($flatArgs) # Capture each invocation's arguments as a new array
                return 'Scan results' 
            }
            
            $formats = @('json', 'table')
            foreach ($format in $formats) {
                $result = Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat $format
            }
            
            # Verify osv-scanner was called once for each format
            Should -Invoke -CommandName 'osv-scanner' -Times $formats.Count -Exactly
            
            # Verify each format was used correctly
            for ($i = 0; $i -lt $formats.Count; $i++) {
                $format = $formats[$i]
                $argsForCall = $script:capturedArgsList[$i]
                
                # Convert to string array for comparison
                $argsStrings = @()
                foreach ($arg in $argsForCall) {
                    $argsStrings += $arg.ToString()
                }
                
                $argsStrings | Should -Contain '--format'
                $argsStrings | Should -Contain $format
            }
        }
        
        It 'Handles osv-scanner execution errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' -MockWith { throw 'Execution failed' }
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Validates OutputFormat parameter' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            { Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat 'invalid' } | 
            Should -Throw
        }
        
        It 'Tests osv-scanner with json format' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            # Capture arguments
            $script:capturedArgs = $null
            Mock -CommandName 'osv-scanner' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Flatten arguments array - when called with & osv-scanner $args, PowerShell expands the array
                $flatArgs = @()
                foreach ($arg in $Arguments) {
                    if ($arg -is [array]) {
                        $flatArgs += $arg
                    }
                    else {
                        $flatArgs += $arg
                    }
                }
                $script:capturedArgs = $flatArgs
                return 'Scan results' 
            }
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat 'json'
            
            Should -Invoke -CommandName 'osv-scanner' -Times 1 -Exactly
            
            # Verify arguments
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            
            # Convert to string array for comparison
            $argsStrings = @()
            foreach ($arg in $script:capturedArgs) {
                $argsStrings += $arg.ToString()
            }
            
            $argsStrings | Should -Contain '--format'
            $argsStrings | Should -Contain 'json'
        }
        
        It 'Handles whitespace-only path' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-OSVScan -Path '   '
                # Should use current directory as default
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Handles osv-scanner path not found' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            
            $result = Invoke-OSVScan -Path 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Uses default path when osv-scanner path is null' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-OSVScan -Path $null
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Handles multiple pipeline inputs' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' -MockWith { return 'Scan results' }
            
            $paths = @($script:TestRepoPath, $script:TestFile)
            $results = $paths | Invoke-OSVScan
            
            # Should process each path
            Should -Invoke -CommandName 'osv-scanner' -Times 2
        }
        
        It 'Tests osv-scanner stderr output handling' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' { 
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'osv-scanner' -Times 1
        }
        
        It 'Tests osv-scanner catch block error handling' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('osv-scanner not found') }
            Mock Write-Error { }
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Tests osv-scanner Write-Error message format' {
            Setup-AvailableCommandMock -CommandName 'osv-scanner'
            Mock -CommandName 'osv-scanner' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('osv-scanner not found') }
            Mock Write-Error { }
            
            $result = Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1 -ParameterFilter {
                $Message -like '*Failed to run osv-scanner*'
            }
        }
    }
}

