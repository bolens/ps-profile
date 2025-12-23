# ===============================================
# TestExecution.ps1
# Test script execution and performance utilities
# ===============================================

<#
.SYNOPSIS
    Executes transient PowerShell script content in a separate process.
.DESCRIPTION
    Writes the supplied script content to a temp file, runs it with pwsh, captures output, and cleans up the file.
.PARAMETER ScriptContent
    The PowerShell code to execute.
.OUTPUTS
    System.Object
#>
function Invoke-TestPwshScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent
    )

    # Use test-data directory instead of system temp
    # Note: Get-TestRepoRoot should be available from TestSupport.ps1 loading TestPaths.ps1 first
    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $testDataRoot = Join-Path $repoRoot 'tests' 'test-data'
    
    # Ensure test-data directory exists
    if ($testDataRoot -and -not [string]::IsNullOrWhiteSpace($testDataRoot) -and -not (Test-Path -LiteralPath $testDataRoot)) {
        try {
            New-Item -ItemType Directory -Path $testDataRoot -Force | Out-Null
        }
        catch {
            throw "Failed to create test-data directory '$testDataRoot': $($_.Exception.Message)"
        }
    }
    
    $tempFile = Join-Path $testDataRoot ([System.IO.Path]::GetRandomFileName() + '.ps1')
    
    try {
        Set-Content -Path $tempFile -Value $ScriptContent -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        throw "Failed to write temporary test script to '$tempFile': $($_.Exception.Message)"
    }

    try {
        if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            throw "pwsh command not found. PowerShell Core must be installed to use this function."
        }
        
        $output = & pwsh -NoProfile -File $tempFile 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -ne 0) {
            $errorMessage = if ($output) { $output -join "`n" } else { "Unknown error" }
            throw "Test script failed with exit code $exitCode : $errorMessage"
        }
        
        return $output
    }
    catch {
        Write-Error "Failed to execute test script '$tempFile': $($_.Exception.Message)"
        throw
    }
    finally {
        if ($tempFile -and -not [string]::IsNullOrWhiteSpace($tempFile) -and (Test-Path -LiteralPath $tempFile)) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Resolves a performance threshold from an environment variable.
.DESCRIPTION
    Returns the integer stored in the specified environment variable when valid, otherwise the provided default.
.PARAMETER EnvironmentVariable
    Name of the environment variable that may override the default threshold.
.PARAMETER Default
    Fallback value used when no override is present or valid.
.OUTPUTS
    System.Int32
#>
function Get-PerformanceThreshold {
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentVariable,

        [Parameter(Mandatory)]
        [int]$Default
    )

    $rawValue = [Environment]::GetEnvironmentVariable($EnvironmentVariable)

    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return $Default
    }

    $parsed = 0
    if ([int]::TryParse($rawValue, [ref]$parsed) -and $parsed -gt 0) {
        return $parsed
    }

    return $Default
}

