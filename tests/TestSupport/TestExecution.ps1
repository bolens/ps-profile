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
<#
.SYNOPSIS
    Runs a script file in a child pwsh process without interactive prompts.
.DESCRIPTION
    Executes scripts the same way behavioral unit tests do: non-interactive child
    process, optional per-invocation environment overrides, captured output, and
    preserved exit codes. Never throws on non-zero exit codes.
.PARAMETER ScriptPath
    Path to the .ps1 script to execute.
.PARAMETER ArgumentList
    Arguments forwarded to the script.
.PARAMETER EnvironmentVariables
    Process environment variables applied only for this invocation.
.OUTPUTS
    PSCustomObject with ExitCode and Output properties.
#>
function Invoke-TestScriptFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [string[]]$ArgumentList = @(),

        [hashtable]$EnvironmentVariables = @{}
    )

    $previousValues = [ordered]@{}
    foreach ($key in $EnvironmentVariables.Keys) {
        $previousValues[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        $value = $EnvironmentVariables[$key]
        Set-Item -Path "Env:$key" -Value ([string]$value)
    }

    try {
        $output = & pwsh -NoProfile -File $ScriptPath @ArgumentList 2>&1 | Out-String
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }
    finally {
        foreach ($key in $previousValues.Keys) {
            if ($null -eq $previousValues[$key]) {
                Remove-Item -Path "Env:$key" -ErrorAction SilentlyContinue
            }
            else {
                Set-Item -Path "Env:$key" -Value $previousValues[$key]
            }
        }
    }
}

function Invoke-TestPwshScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent,

        [string]$RepositoryRoot
    )

    # Use test-data directory instead of system temp
    # Note: Get-TestRepoRoot should be available from TestSupport.ps1 loading TestPaths.ps1 first
    $repoRoot = if ($RepositoryRoot) { $RepositoryRoot } else { Get-TestRepoRoot -StartPath $PSScriptRoot }
    $escapedRepoRoot = $repoRoot.Replace("'", "''")
    $scriptPrefix = @"
`$env:PS_PROFILE_TEST_MODE = '1'
`$env:PS_PROFILE_REPO_ROOT = '$escapedRepoRoot'
"@

    $ScriptContent = $scriptPrefix + [Environment]::NewLine + $ScriptContent
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
            $errorMessage = if ($output) { ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine } else { 'Unknown error' }
            throw "Test script failed with exit code $exitCode : $errorMessage"
        }

        if ($null -eq $output) {
            return ''
        }

        if ($output -is [string]) {
            return $output
        }

        return ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
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

<#
.SYNOPSIS
    Sets script-scoped performance thresholds for fragment performance tests.
.DESCRIPTION
    Populates MaxFragmentLoadTimeMs, MaxRepeatLoadTimeMs, MaxFunctionExecTimeMs,
    MaxIdempotencyTimeMs, and MaxLookupTimeMs using Get-PerformanceThreshold.
    Defaults include headroom for CI and developer machines (similar to the 3x
    margin used in performance.tests.ps1). Override per-fragment via
    PS_PROFILE_{PREFIX}_MAX_* environment variables.
.PARAMETER Prefix
    Short name used to build PS_PROFILE_{PREFIX}_* environment variables.
#>
function Initialize-FragmentPerformanceThresholds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix,

        [int]$LoadMs = 4500,
        [int]$RepeatLoadMs = 4000,
        [int]$FunctionMs = 4000,
        [int]$IdempotencyMs = 4000,
        [int]$LookupMs = 1000
    )

    $key = ($Prefix -replace '[^A-Za-z0-9]', '_').ToUpperInvariant()
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable "PS_PROFILE_${key}_MAX_LOAD_MS" -Default $LoadMs
    $script:MaxRepeatLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable "PS_PROFILE_${key}_MAX_REPEAT_LOAD_MS" -Default $RepeatLoadMs
    $script:MaxFunctionExecTimeMs = Get-PerformanceThreshold -EnvironmentVariable "PS_PROFILE_${key}_MAX_FUNCTION_MS" -Default $FunctionMs
    $script:MaxIdempotencyTimeMs = Get-PerformanceThreshold -EnvironmentVariable "PS_PROFILE_${key}_MAX_IDEMPOTENCY_MS" -Default $IdempotencyMs
    $script:MaxLookupTimeMs = Get-PerformanceThreshold -EnvironmentVariable "PS_PROFILE_${key}_MAX_LOOKUP_MS" -Default $LookupMs
}

