# ===============================================
# profile-security-tools-dangerzone.tests.ps1
# Unit tests for Invoke-DangerzoneConvert function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

# Helper function is now in PesterMocks.psm1 module

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'security-tools.ps1')
    
    # Create test directories
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestFile = Join-Path $TestDrive 'test-file.pdf'
        Set-Content -Path $script:TestFile -Value 'PDF content'
    }
}

Describe 'security-tools.ps1 - Invoke-DangerzoneConvert' {
    BeforeEach {
        # Clear command cache to ensure mocks work correctly
        if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
            Remove-TestCachedCommandCacheEntry -Name 'dangerzone' -ErrorAction SilentlyContinue
        }
    }
    
    Context 'Invoke-DangerzoneConvert' {
        It 'Returns null when dangerzone is not available' {
            $cmdName = 'dangerzone'
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
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when input file does not exist' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            
            $result = Invoke-DangerzoneConvert -InputPath 'C:\NonExistent\File.pdf' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls dangerzone with correct arguments when tool is available' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            
            # Capture arguments in a variable
            # When called with & dangerzone $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'dangerzone' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Conversion results' 
            }
            
            $outputPath = Join-Path $TestDrive 'output.safe.pdf'
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -OutputPath $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'dangerzone' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain $script:TestFile
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain $outputPath
        }
        
        It 'Generates default output path when not specified' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            
            # Capture arguments in a variable
            # When called with & dangerzone $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'dangerzone' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Conversion results' 
            }
            
            $testPdf = Join-Path $TestDrive 'test.pdf'
            Set-Content -Path $testPdf -Value 'PDF content'
            
            $result = Invoke-DangerzoneConvert -InputPath $testPdf
            
            $expectedOutput = Join-Path $TestDrive 'test.safe.pdf'
            Should -Invoke -CommandName 'dangerzone' -Times 1 -Exactly
            $script:capturedArgs[0] | Should -Be $testPdf
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain $expectedOutput
        }
        
        It 'Handles dangerzone execution errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            Mock -CommandName 'dangerzone' -MockWith { throw 'Execution failed' }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Tests dangerzone with custom output path' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            
            # Capture arguments in a variable
            # When called with & dangerzone $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'dangerzone' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Conversion results' 
            }
            
            $outputPath = Join-Path $TestDrive 'output.pdf'
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -OutputPath $outputPath
            
            Should -Invoke -CommandName 'dangerzone' -Times 1 -Exactly
            $script:capturedArgs[0] | Should -Be $script:TestFile
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain $outputPath
        }
        
        It 'Tests dangerzone default output path generation' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            
            # Capture arguments in a variable
            # When called with & dangerzone $args, PowerShell expands the array
            # So $args in the mock will contain the individual elements
            $capturedArgs = $null
            Mock -CommandName 'dangerzone' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Capture all arguments (PowerShell expands the array when using &)
                $script:capturedArgs = $Arguments
                return 'Conversion results' 
            }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile
            
            $expectedOutput = Join-Path (Split-Path -Parent $script:TestFile) 'test-file.safe.pdf'
            Should -Invoke -CommandName 'dangerzone' -Times 1 -Exactly
            $script:capturedArgs[0] | Should -Be $script:TestFile
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain $expectedOutput
        }
        
        It 'Handles dangerzone input file not found' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            
            $result = Invoke-DangerzoneConvert -InputPath 'C:\NonExistent\File.pdf' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Adds Docker requirement to dangerzone install hint when not present' {
            Mock-CommandAvailabilityPester -CommandName 'dangerzone' -Available $false
            
            # Create a function mock for Get-ToolInstallHint so Get-Command can find it
            function Get-ToolInstallHint {
                param([string]$ToolName, [string]$RepoRoot)
                return 'Install with: scoop install dangerzone'
            }
            
            # Mock Get-Command to return Get-ToolInstallHint function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-ToolInstallHint' } -MockWith {
                return @{ Name = 'Get-ToolInstallHint' }
            }
            
            # Capture arguments for Write-MissingToolWarning
            $script:capturedTool = $null
            $script:capturedInstallHint = $null
            Mock Write-MissingToolWarning -MockWith {
                param([string]$Tool, [string]$InstallHint)
                $script:capturedTool = $Tool
                $script:capturedInstallHint = $InstallHint
            }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue
            
            Should -Invoke Write-MissingToolWarning -Times 1 -Exactly
            if ($null -eq $script:capturedTool -or $null -eq $script:capturedInstallHint) {
                throw "Mock was called but captured values are null. Mock may not be intercepting correctly."
            }
            $script:capturedTool | Should -Be 'dangerzone'
            $script:capturedInstallHint | Should -Match 'requires Docker'
        }
        
        It 'Does not add Docker requirement when already present in install hint' {
            Mock-CommandAvailabilityPester -CommandName 'dangerzone' -Available $false
            
            # Create a function mock for Get-ToolInstallHint so Get-Command can find it
            function Get-ToolInstallHint {
                param([string]$ToolName, [string]$RepoRoot)
                return 'Install with: scoop install dangerzone (requires Docker)'
            }
            
            # Mock Get-Command to return Get-ToolInstallHint function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-ToolInstallHint' } -MockWith {
                return @{ Name = 'Get-ToolInstallHint' }
            }
            
            # Capture arguments for Write-MissingToolWarning
            $script:capturedTool = $null
            $script:capturedInstallHint = $null
            Mock Write-MissingToolWarning -MockWith {
                param([string]$Tool, [string]$InstallHint)
                $script:capturedTool = $Tool
                $script:capturedInstallHint = $InstallHint
            }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue
            
            # Should not duplicate Docker requirement
            Should -Invoke Write-MissingToolWarning -Times 1 -Exactly
            if ($null -eq $script:capturedInstallHint) {
                throw "Mock was called but capturedInstallHint is null. Mock may not be intercepting correctly."
            }
            # Verify Docker requirement is not duplicated (should appear only once)
            ($script:capturedInstallHint -split 'requires Docker').Count | Should -Be 2
        }
        
        It 'Tests dangerzone install hint Docker check when Docker already mentioned' {
            Mock-CommandAvailabilityPester -CommandName 'dangerzone' -Available $false
            
            # Create a function mock for Get-ToolInstallHint so Get-Command can find it
            function Get-ToolInstallHint {
                param([string]$ToolName, [string]$RepoRoot)
                return 'Install with: scoop install dangerzone (requires Docker)'
            }
            
            # Mock Get-Command to return Get-ToolInstallHint function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-ToolInstallHint' } -MockWith {
                return @{ Name = 'Get-ToolInstallHint' }
            }
            
            # Capture arguments for Write-MissingToolWarning
            $script:capturedInstallHint = $null
            Mock Write-MissingToolWarning -MockWith {
                param([string]$Tool, [string]$InstallHint)
                $script:capturedInstallHint = $InstallHint
            }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile
            
            Should -Invoke Write-MissingToolWarning -Times 1 -Exactly
            if ($null -eq $script:capturedInstallHint) {
                throw "Mock was called but capturedInstallHint is null. Mock may not be intercepting correctly."
            }
            $script:capturedInstallHint | Should -Be 'Install with: scoop install dangerzone (requires Docker)'
        }
        
        It 'Tests dangerzone install hint Docker append when not mentioned' {
            Mock-CommandAvailabilityPester -CommandName 'dangerzone' -Available $false
            
            # Create a function mock for Get-ToolInstallHint so Get-Command can find it
            function Get-ToolInstallHint {
                param([string]$ToolName, [string]$RepoRoot)
                return 'Install with: scoop install dangerzone'
            }
            
            # Mock Get-Command to return Get-ToolInstallHint function when requested, otherwise pass through
            Mock Get-Command -ParameterFilter { $Name -eq 'Get-ToolInstallHint' } -MockWith {
                return @{ Name = 'Get-ToolInstallHint' }
            }
            
            # Capture arguments for Write-MissingToolWarning
            $script:capturedInstallHint = $null
            Mock Write-MissingToolWarning -MockWith {
                param([string]$Tool, [string]$InstallHint)
                $script:capturedInstallHint = $InstallHint
            }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile
            
            Should -Invoke Write-MissingToolWarning -Times 1 -Exactly
            if ($null -eq $script:capturedInstallHint) {
                throw "Mock was called but capturedInstallHint is null. Mock may not be intercepting correctly."
            }
            $script:capturedInstallHint | Should -Be 'Install with: scoop install dangerzone (requires Docker)'
        }
        
        It 'Tests dangerzone stderr output handling' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            Mock -CommandName 'dangerzone' -MockWith { 
                [Console]::Error.WriteLine('Warning message')
                return 'Conversion results'
            }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'dangerzone' -Times 1
        }
        
        It 'Tests dangerzone catch block error handling' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            Mock -CommandName 'dangerzone' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('dangerzone not found') }
            Mock Write-Error { }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Tests dangerzone Write-Error message format' {
            Setup-AvailableCommandMock -CommandName 'dangerzone'
            Mock -CommandName 'dangerzone' -MockWith { throw [System.Management.Automation.CommandNotFoundException]::new('dangerzone not found') }
            Mock Write-Error { }
            
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1 -ParameterFilter {
                $Message -like '*Failed to run dangerzone*'
            }
        }
    }
}


