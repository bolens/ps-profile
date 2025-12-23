# ===============================================
# profile-security-tools-gitleaks.tests.ps1
# Unit tests for Invoke-GitLeaksScan function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

# Helper function to set up mocks for unavailable commands
# Uses Mock-CommandAvailabilityPester with -Available $false
function global:Setup-UnavailableCommandMock {
    param([string]$CommandName)
    Mock-CommandAvailabilityPester -CommandName $CommandName -Available $false
}

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

Describe 'security-tools.ps1 - Invoke-GitLeaksScan' {
    BeforeEach {
        # CRITICAL: Clear command cache FIRST to ensure mocks work correctly
        # The cache is checked BEFORE the mock can intercept, so we must clear it
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        # Also clear the specific cache entry directly
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gitleaks', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('GITLEAKS', [ref]$null)
        }
        
        # Remove from AssumedAvailableCommands to ensure clean state
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('gitleaks', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('GITLEAKS', [ref]$null)
        }
        
        # Remove any function mocks that might exist
        Remove-Item -Path "Function:\gitleaks" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:gitleaks" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Invoke-GitLeaksScan' {
        It 'Returns null when gitleaks is not available' {
            # Clear cache and remove from AssumedAvailableCommands before mocking
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:TestCachedCommandCache.TryRemove('gitleaks', [ref]$null)
                $null = $global:TestCachedCommandCache.TryRemove('GITLEAKS', [ref]$null)
            }
            if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:AssumedAvailableCommands.TryRemove('gitleaks', [ref]$null)
                $null = $global:AssumedAvailableCommands.TryRemove('GITLEAKS', [ref]$null)
            }
            
            # Remove any function mocks
            Remove-Item -Path "Function:\gitleaks" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:gitleaks" -Force -ErrorAction SilentlyContinue
            
            # Set up mock for unavailable command
            Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $false
            
            # Also ensure Get-Command returns null for gitleaks
            Mock Get-Command -ParameterFilter { $Name -eq 'gitleaks' } -MockWith { return $null }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue
            
            # The function should return null when the command is not available
            # It may also write a warning, but the return value should be null
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when repository path does not exist' {
            # Mock command as available and mock the actual command
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            Mock -CommandName 'gitleaks' -MockWith { return 'Scan results' }
            
            $result = Invoke-GitLeaksScan -RepositoryPath 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls gitleaks with correct arguments when tool is available' {
            # Mock command as available and mock the actual command
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'gitleaks' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat 'json'
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'gitleaks' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain 'detect'
            $script:capturedArgs | Should -Contain '--source'
            $script:capturedArgs | Should -Contain '--format'
            $script:capturedArgs | Should -Contain 'json'
        }
        
        It 'Includes report path when specified' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'gitleaks' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $reportPath = Join-Path $TestDrive 'report.json'
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ReportPath $reportPath
            
            Should -Invoke -CommandName 'gitleaks' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '--report-path'
            $script:capturedArgs | Should -Contain $reportPath
        }
        
        It 'Includes no-git flag when report path is not specified' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            
            # Capture arguments in a variable
            $capturedArgs = $null
            Mock -CommandName 'gitleaks' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Scan results' 
            }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
            Should -Invoke -CommandName 'gitleaks' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
            }
            $script:capturedArgs | Should -Contain '--no-git'
        }
        
        It 'Uses default repository path when not specified' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            Mock -CommandName 'gitleaks' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-GitLeaksScan
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Supports different output formats' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            
            # Capture arguments for each call in a list
            $script:capturedArgsList = @()
            Mock -CommandName 'gitleaks' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Flatten arguments array - when called with & gitleaks $args, PowerShell expands the array
                $flatArgs = @()
                foreach ($arg in $Arguments) {
                    if ($arg -is [array]) {
                        $flatArgs += $arg
                    }
                    else {
                        $flatArgs += $arg
                    }
                }
                $script:capturedArgsList += , @($flatArgs) # Capture each invocation's arguments as a new array
                return 'Scan results' 
            }
            
            $formats = @('json', 'csv', 'sarif')
            foreach ($format in $formats) {
                $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat $format
            }
            
            # Verify gitleaks was called once for each format
            Should -Invoke -CommandName 'gitleaks' -Times $formats.Count -Exactly
            
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
        
        It 'Handles gitleaks execution errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            Mock -CommandName 'gitleaks' -MockWith { throw 'Execution failed' }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles empty repository path' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            
            # When RepositoryPath is empty, the function uses current directory
            # Mock Test-Path to return false for the current directory to simulate non-existent path
            $currentPath = (Get-Location).Path
            Mock Test-Path { return $false } -ParameterFilter { $LiteralPath -eq $currentPath -and $PathType -eq 'Container' }
            
            $result = Invoke-GitLeaksScan -RepositoryPath '' -ErrorAction SilentlyContinue
            
            # Should return null when the path doesn't exist
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles null repository path' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            Mock -CommandName 'gitleaks' -MockWith { return 'Scan results' }
            
            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-GitLeaksScan -RepositoryPath $null
                # Should use default path (current location)
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'Handles whitespace-only repository path' {
            Setup-AvailableCommandMock -CommandName 'gitleaks'
            
            # When RepositoryPath is whitespace-only, the function uses current directory
            # Mock Test-Path to return false for the current directory to simulate non-existent path
            $currentPath = (Get-Location).Path
            Mock Test-Path { return $false } -ParameterFilter { $LiteralPath -eq $currentPath -and $PathType -eq 'Container' }
            
            $result = Invoke-GitLeaksScan -RepositoryPath '   ' -ErrorAction SilentlyContinue
            
            # Should return null when the path doesn't exist
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles Write-MissingToolWarning fallback when function not available' {
            Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $false
            
            # CRITICAL: Get-Command checks function provider FIRST, so we must remove the function
            # Remove from all possible function paths (like fragment tests do)
            Remove-Item -Path "Function:\Write-MissingToolWarning" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:Write-MissingToolWarning" -Force -ErrorAction SilentlyContinue
            
            # Mock Get-Command to return null for Write-MissingToolWarning
            # Use the exact simple pattern from fragment tests: { $Name -eq 'FunctionName' }
            Mock Get-Command -ParameterFilter { $Name -eq 'Write-MissingToolWarning' } -MockWith {
                return $null
            }
            
            # Capture arguments for Write-Warning
            $script:capturedWriteWarningArgs = @()
            Mock Write-Warning -MockWith {
                param($Message)
                $script:capturedWriteWarningArgs += $Message
            }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
            # Should fall back to Write-Warning when Write-MissingToolWarning is not available
            Should -Invoke Write-Warning -Times 1
            if ($script:capturedWriteWarningArgs.Count -gt 0) {
                $script:capturedWriteWarningArgs[0] | Should -Match 'gitleaks'
            }
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles Get-ToolInstallHint fallback when function not available' {
            Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $false
            
            # Remove Get-ToolInstallHint function if it exists (like fragment tests do)
            Remove-Item -Path "Function:\Get-ToolInstallHint" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:Get-ToolInstallHint" -Force -ErrorAction SilentlyContinue
            
            # Try to remove from module if it exists
            Remove-Module Command -ErrorAction SilentlyContinue
            Remove-Module Utilities -ErrorAction SilentlyContinue
            
            # Create a function mock for Write-MissingToolWarning so Get-Command can find it
            function Write-MissingToolWarning {
                param([string]$Tool, [string]$InstallHint)
            }
            
            # Mock Get-Command with simple ParameterFilter pattern from fragment tests
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-ToolInstallHint' } -MockWith {
                return $null
            }
            
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-RepoRoot' } -MockWith {
                return $null
            }
            
            Mock Get-Command -ParameterFilter { $Name -eq 'Write-MissingToolWarning' } -MockWith {
                return @{ Name = 'Write-MissingToolWarning' }
            }
            
            # Capture arguments for Write-MissingToolWarning
            $script:capturedWriteMissingToolWarningArgs = $null
            Mock Write-MissingToolWarning -MockWith {
                param($Tool, $InstallHint)
                $script:capturedWriteMissingToolWarningArgs = @{
                    Tool        = $Tool
                    InstallHint = $InstallHint
                }
            }
            
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
            # Should call Write-MissingToolWarning with fallback install hint
            Should -Invoke Write-MissingToolWarning -Times 1
            if ($null -ne $script:capturedWriteMissingToolWarningArgs) {
                $script:capturedWriteMissingToolWarningArgs.Tool | Should -Be 'gitleaks'
                $script:capturedWriteMissingToolWarningArgs.InstallHint | Should -BeLike '*scoop install gitleaks*'
            }
            $result | Should -BeNullOrEmpty
        }
    }
}
        
Context 'Parameter Validation' {
    It 'Validates OutputFormat parameter' {
        Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $true
        
        { Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat 'invalid' } | 
        Should -Throw
    }
}

Context 'Additional Functionality' {
    It 'Tests gitleaks with all output formats' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
        
        # Capture arguments for each call in a list
        $script:capturedArgsList = @()
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            # Flatten arguments array - when called with & gitleaks $args, PowerShell expands the array
            $flatArgs = @()
            foreach ($arg in $Arguments) {
                if ($arg -is [array]) {
                    $flatArgs += $arg
                }
                else {
                    $flatArgs += $arg
                }
            }
            $script:capturedArgsList += , @($flatArgs) # Capture each invocation's arguments as a new array
            return 'Scan results' 
        }
        
        $formats = @('json', 'csv', 'sarif')
        foreach ($format in $formats) {
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat $format
        }
        
        # Verify gitleaks was called once for each format
        Should -Invoke -CommandName 'gitleaks' -Times $formats.Count -Exactly
        
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
        
    It 'Tests gitleaks with both ReportPath and OutputFormat' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
    
        # Capture arguments
        $script:capturedArgs = $null
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            $script:capturedArgs = $Arguments
            return 'Scan results' 
        }
    
        $reportPath = Join-Path $TestDrive 'report.json'
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ReportPath $reportPath -OutputFormat 'json'
            
        # Verify gitleaks was called
        Should -Invoke -CommandName 'gitleaks' -Times 1 -Exactly
    
        # Verify arguments
        if ($null -eq $script:capturedArgs) {
            throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
        }
        $script:capturedArgs | Should -Contain '--report-path'
        $script:capturedArgs | Should -Contain $reportPath
        $script:capturedArgs | Should -Contain '--format'
        $script:capturedArgs | Should -Contain 'json'
        $script:capturedArgs | Should -Not -Contain '--no-git'
    }
        
    It 'Handles Test-Path returning false for valid-looking path' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
        Mock Test-Path { return $false } -ParameterFilter { 
            $LiteralPath -eq $script:TestRepoPath -and $PathType -eq 'Container' 
        }
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue
            
        $result | Should -BeNullOrEmpty
    }
        
    It 'Handles tool command returning empty string' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
    
        # Mock gitleaks to return empty string
        # Note: When using 2>&1, PowerShell may wrap the output, so we need to ensure empty string is returned correctly
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            return [string]::Empty
        }
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
        # Empty string should be returned as-is
        $result | Should -Be ''
    }
        
    It 'Handles tool command returning null' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
    
        # Mock gitleaks to return null
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            return $null
        }
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
        # Null should be returned as null
        $result | Should -BeNullOrEmpty
    }
        
    It 'Tests gitleaks stderr output handling' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
    
        # Mock gitleaks to simulate stderr output
        # Since the implementation uses 2>&1, stderr is merged with stdout
        # We'll simulate this by returning a string that includes both
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            # Simulate stderr output being merged with stdout via 2>&1
            # In real scenarios, 2>&1 would capture both streams
            return "Warning message`nScan results"
        }
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath
            
        # Result should contain both the warning and scan results
        $result | Should -Not -BeNullOrEmpty
        $resultString = if ($result -is [array]) { $result -join "`n" } else { $result.ToString() }
        $resultString | Should -Match 'Scan results'
        Should -Invoke -CommandName 'gitleaks' -Times 1
    }
        
    It 'Tests gitleaks catch block error handling' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
    
        # Mock gitleaks to throw an exception
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            throw [System.Management.Automation.CommandNotFoundException]::new('gitleaks not found')
        }
    
        # Mock Write-Error to capture calls
        Mock Write-Error { }
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue
            
        # Should return null when exception is caught
        $result | Should -BeNullOrEmpty
        # Write-Error should be called once in the catch block
        Should -Invoke Write-Error -Times 1
    }
        
    It 'Tests gitleaks Write-Error message format' {
        Setup-AvailableCommandMock -CommandName 'gitleaks'
    
        # Mock gitleaks to throw an exception
        Mock -CommandName 'gitleaks' -MockWith { 
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            throw [System.Management.Automation.CommandNotFoundException]::new('gitleaks not found')
        }
    
        # Capture Write-Error calls to verify message format
        $script:capturedWriteErrorMessages = @()
        Mock Write-Error -MockWith {
            param($Message)
            $script:capturedWriteErrorMessages += $Message
        }
            
        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue
            
        # Should return null when exception is caught
        $result | Should -BeNullOrEmpty
    
        # Write-Error should be called once
        Should -Invoke Write-Error -Times 1
    
        # Verify the error message format
        if ($script:capturedWriteErrorMessages.Count -gt 0) {
            $script:capturedWriteErrorMessages[0] | Should -Match 'Failed to run gitleaks'
        }
    }
}
