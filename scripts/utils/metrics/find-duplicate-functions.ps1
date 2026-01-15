<#
scripts/utils/find-duplicate-functions.ps1

.SYNOPSIS
    Finds duplicate function definitions in profile.d directory.

.DESCRIPTION
    Scans all PowerShell script files in the profile.d directory and identifies
    functions that are defined in multiple files. This helps detect potential conflicts
    or duplicate function definitions that could cause issues.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\find-duplicate-functions.ps1

    Scans profile.d directory and reports any duplicate function definitions.
#>

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'RegexUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileContent' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Collections' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Parallel' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get profile directory using shared function
try {
    $profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    Test-PathExists -Path $profileDir -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

$files = Get-PowerShellScripts -Path $profileDir -SortByName

# Use Collections module for better performance
$found = New-ObjectList

# Get compiled regex pattern from RegexUtilities module
$patterns = Get-CommonRegexPatterns
$functionRegex = $patterns['FunctionDefinition']

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.find-duplicates] Starting duplicate function detection"
    Write-Verbose "[metrics.find-duplicates] Files to scan: $($files.Count)"
}

Write-ScriptMessage -Message "Scanning $($files.Count) file(s) for duplicate functions..."

# Process files in parallel for better performance
# Note: Invoke-Parallel uses Start-Job which runs in separate process, so we need to recreate regex in scriptblock
$functionRegexPattern = "function\s+([A-Za-z0-9_-]+)\s*\{"
$scanStartTime = Get-Date
$scanResults = Invoke-Parallel -Items $files -ScriptBlock {
    param($File)
    
    $fileFunctions = New-ObjectList
    
    try {
        $content = Read-FileContent -Path $File.FullName
        # Recreate regex in scriptblock since we can't pass compiled regex across process boundaries
        $functionRegex = [regex]::new($using:functionRegexPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        
        foreach ($match in $functionRegex.Matches($content)) {
            $fileFunctions.Add([PSCustomObject]@{
                    File = $File.FullName
                    Name = $match.Groups[1].Value
                })
        }
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to scan file for duplicate functions" -OperationName 'metrics.find-duplicates.scan' -Context @{
                file_path = $File.FullName
            } -Code 'FileScanFailed'
        }
        else {
            Write-Warning "Failed to scan $($File.FullName): $($_.Exception.Message)"
        }
    }
    
    return $fileFunctions.ToArray()
} -ThrottleLimit 5

$scanDuration = ((Get-Date) - $scanStartTime).TotalMilliseconds

# Level 2: Scan timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.find-duplicates] File scan completed in ${scanDuration}ms"
}

# Collect results
foreach ($result in $scanResults) {
    if ($result) {
        $found.AddRange($result)
    }
}

# Level 2: Results details
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.find-duplicates] Found $($found.Count) function definition(s) across all files"
}

$groupStartTime = Get-Date
$groups = $found | Group-Object Name | Where-Object { $_.Count -gt 1 }
$groupDuration = ((Get-Date) - $groupStartTime).TotalMilliseconds

# Level 2: Grouping timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.find-duplicates] Grouping completed in ${groupDuration}ms"
    Write-Verbose "[metrics.find-duplicates] Duplicate groups found: $($groups.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalDuration = $scanDuration + $groupDuration
    Write-Host "  [metrics.find-duplicates] Performance - Scan: ${scanDuration}ms, Group: ${groupDuration}ms, Total: ${totalDuration}ms, Functions: $($found.Count), Duplicates: $($groups.Count)" -ForegroundColor DarkGray
}

if ($groups.Count -eq 0) {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "No duplicate function definitions found in profile.d"
}

foreach ($g in $groups) {
    Write-ScriptMessage -Message "Function: $($g.Name)"
    $g.Group | ForEach-Object { Write-ScriptMessage -Message "  - $($_.File)" }
    Write-ScriptMessage -Message ""
}

# Exit with validation failure if duplicates found (non-zero exit indicates issue)
Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Found $($groups.Count) duplicate function definition(s)"

