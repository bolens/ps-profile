# ===============================================
# MockPython.psm1
# Python tool mocking utilities for tests
# ===============================================

<#
.SYNOPSIS
    Mocks Python-related functions for testing.
.DESCRIPTION
    Provides mocking utilities for Python functions including:
    - Get-PythonPath
    - Get-DataFrameLibraryPreference
    - Test-PythonPackageAvailable
    - Python script execution
.PARAMETER PythonPath
    Mock Python executable path. Defaults to 'python'.
.PARAMETER PandasAvailable
    Whether pandas should be reported as available. Defaults to $true.
.PARAMETER PolarsAvailable
    Whether polars should be reported as available. Defaults to $true.
.PARAMETER PyreadstatAvailable
    Whether pyreadstat should be reported as available. Defaults to $true.
.PARAMETER PreferredLibrary
    Preferred data frame library ('pandas', 'polars', or 'auto'). Defaults to 'auto'.
.EXAMPLE
    Mock-PythonTools -PandasAvailable $true -PolarsAvailable $false
    Mocks Python tools with pandas available but polars not available.
#>
function Mock-PythonTools {
    [CmdletBinding()]
    param(
        [string]$PythonPath = 'python',
        
        [bool]$PandasAvailable = $true,
        
        [bool]$PolarsAvailable = $true,
        
        [bool]$PyreadstatAvailable = $true,
        
        [ValidateSet('pandas', 'polars', 'auto')]
        [string]$PreferredLibrary = 'auto'
    )
    
    if ($env:PS_PROFILE_TEST_MODE -ne '1') {
        Write-Warning "Mock-PythonTools should only be called in test mode (PS_PROFILE_TEST_MODE=1)"
        return
    }
    
    # Mock Get-PythonPath
    if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
        Mock -CommandName Get-PythonPath -MockWith { return $PythonPath } -Scope It
    }
    else {
        # Create function mock if command doesn't exist
        Set-Item -Path Function:\Get-PythonPath -Value { return $PythonPath } -Force -ErrorAction SilentlyContinue
    }
    
    # Mock Get-DataFrameLibraryPreference
    $libInfo = @{
        Library         = if ($PreferredLibrary -eq 'auto') {
            if ($PandasAvailable) { 'pandas' } elseif ($PolarsAvailable) { 'polars' } else { 'pandas' }
        }
        else {
            $PreferredLibrary
        }
        Available       = $PandasAvailable -or $PolarsAvailable
        BothAvailable   = $PandasAvailable -and $PolarsAvailable
        PandasAvailable = $PandasAvailable
        PolarsAvailable = $PolarsAvailable
    }
    
    if (Get-Command Get-DataFrameLibraryPreference -ErrorAction SilentlyContinue) {
        Mock -CommandName Get-DataFrameLibraryPreference -MockWith { 
            param([string]$PythonCmd)
            return $libInfo
        } -Scope It
    }
    else {
        # Create function mock if command doesn't exist
        $mockScript = {
            param([string]$PythonCmd)
            return $libInfo
        }
        Set-Item -Path Function:\Get-DataFrameLibraryPreference -Value $mockScript -Force -ErrorAction SilentlyContinue
    }
    
    # Mock Test-PythonPackageAvailable
    if (Get-Command Test-PythonPackageAvailable -ErrorAction SilentlyContinue) {
        Mock -CommandName Test-PythonPackageAvailable -MockWith {
            param(
                [Parameter(Mandatory)]
                [string]$PackageName
            )
            
            $packageLower = $PackageName.ToLower()
            switch ($packageLower) {
                'pandas' { return $PandasAvailable }
                'polars' { return $PolarsAvailable }
                'pyreadstat' { return $PyreadstatAvailable }
                default { return $false }
            }
        } -Scope It
    }
    else {
        # Create function mock if command doesn't exist
        $mockScript = {
            param(
                [Parameter(Mandatory)]
                [string]$PackageName
            )
            
            $packageLower = $PackageName.ToLower()
            switch ($packageLower) {
                'pandas' { return $PandasAvailable }
                'polars' { return $PolarsAvailable }
                'pyreadstat' { return $PyreadstatAvailable }
                default { return $false }
            }
        }
        Set-Item -Path Function:\Test-PythonPackageAvailable -Value $mockScript -Force -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Mocks Python script execution.
.DESCRIPTION
    Mocks Python script execution to return specified output without actually running Python.
.PARAMETER ScriptPath
    Path to the Python script (for filtering).
.PARAMETER ReturnValue
    Value to return from the mock execution.
.PARAMETER ExitCode
    Exit code to simulate. Defaults to 0 (success).
.PARAMETER ErrorOutput
    Error output to simulate. If provided, ExitCode should be non-zero.
.EXAMPLE
    Mock-PythonScriptExecution -ScriptPath 'test.py' -ReturnValue '{"result": "success"}' -ExitCode 0
    Mocks a successful Python script execution.
#>
function Mock-PythonScriptExecution {
    [CmdletBinding()]
    param(
        [string]$ScriptPath,
        
        [object]$ReturnValue,
        
        [int]$ExitCode = 0,
        
        [string]$ErrorOutput
    )
    
    if ($env:PS_PROFILE_TEST_MODE -ne '1') {
        Write-Warning "Mock-PythonScriptExecution should only be called in test mode (PS_PROFILE_TEST_MODE=1)"
        return
    }
    
    # Mock Invoke-PythonScript if it exists
    if (Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue) {
        $mockWith = if ($ErrorOutput) {
            { throw $ErrorOutput }
        }
        elseif ($null -ne $ReturnValue) {
            { return $ReturnValue }
        }
        else {
            { return "Mock Python output" }
        }
        
        if ($ScriptPath) {
            Mock -CommandName Invoke-PythonScript -ParameterFilter { $ScriptPath -eq $ScriptPath } -MockWith $mockWith -Scope It
        }
        else {
            Mock -CommandName Invoke-PythonScript -MockWith $mockWith -Scope It
        }
    }
    
    # Also mock direct Python command execution
    # This mocks the & $pythonCmd $scriptPath pattern used in conversion modules
    $pythonCmd = if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
        Get-PythonPath
    }
    else {
        'python'
    }
    
    if ($pythonCmd) {
        $mockWith = if ($ErrorOutput) {
            { 
                $global:LASTEXITCODE = $ExitCode
                Write-Error $ErrorOutput
                throw $ErrorOutput
            }
        }
        else {
            {
                $global:LASTEXITCODE = $ExitCode
                if ($null -ne $ReturnValue) {
                    return $ReturnValue
                }
                return "Mock Python output"
            }
        }
        
        # Mock the command execution operator
        # Note: This is tricky - we can't directly mock &, but we can mock the command itself
        if (Test-Path "Function:\$pythonCmd") {
            Mock -CommandName $pythonCmd -MockWith $mockWith -Scope It
        }
    }
}

<#
.SYNOPSIS
    Sets up default Python mocks for test scenarios.
.DESCRIPTION
    Sets up common Python mocking scenarios for testing conversion functions.
    This is a convenience function that calls Mock-PythonTools with common configurations.
.PARAMETER Scenario
    Test scenario: 'both', 'pandas-only', 'polars-only', 'neither', or 'custom'.
.PARAMETER CustomConfig
    Hashtable with custom configuration (overrides scenario defaults).
.EXAMPLE
    Initialize-PythonMocks -Scenario 'both'
    Sets up mocks with both pandas and polars available.
.EXAMPLE
    Initialize-PythonMocks -Scenario 'pandas-only'
    Sets up mocks with only pandas available.
#>
function Initialize-PythonMocks {
    [CmdletBinding()]
    param(
        [ValidateSet('both', 'pandas-only', 'polars-only', 'neither', 'custom')]
        [string]$Scenario = 'both',
        
        [hashtable]$CustomConfig
    )
    
    if ($env:PS_PROFILE_TEST_MODE -ne '1') {
        Write-Warning "Initialize-PythonMocks should only be called in test mode (PS_PROFILE_TEST_MODE=1)"
        return
    }
    
    $config = switch ($Scenario) {
        'both' {
            @{
                PandasAvailable     = $true
                PolarsAvailable     = $true
                PyreadstatAvailable = $true
                PreferredLibrary    = 'auto'
            }
        }
        'pandas-only' {
            @{
                PandasAvailable     = $true
                PolarsAvailable     = $false
                PyreadstatAvailable = $true
                PreferredLibrary    = 'pandas'
            }
        }
        'polars-only' {
            @{
                PandasAvailable     = $false
                PolarsAvailable     = $true
                PyreadstatAvailable = $true
                PreferredLibrary    = 'polars'
            }
        }
        'neither' {
            @{
                PandasAvailable     = $false
                PolarsAvailable     = $false
                PyreadstatAvailable = $false
                PreferredLibrary    = 'auto'
            }
        }
        'custom' {
            @{
                PandasAvailable     = $CustomConfig.PandasAvailable ?? $true
                PolarsAvailable     = $CustomConfig.PolarsAvailable ?? $true
                PyreadstatAvailable = $CustomConfig.PyreadstatAvailable ?? $true
                PreferredLibrary    = $CustomConfig.PreferredLibrary ?? 'auto'
            }
        }
    }
    
    # Merge custom config if provided
    if ($CustomConfig) {
        foreach ($key in $CustomConfig.Keys) {
            $config[$key] = $CustomConfig[$key]
        }
    }
    
    Mock-PythonTools @config
}

# Export functions
Export-ModuleMember -Function @(
    'Mock-PythonTools',
    'Mock-PythonScriptExecution',
    'Initialize-PythonMocks'
)

