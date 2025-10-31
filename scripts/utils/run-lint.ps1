# Install PSScriptAnalyzer if not present, then run it against profile.d
param(
    [string]$Path
)

if (-not $Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
    $Path = Join-Path $repoRoot 'profile.d'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
if (-not [System.IO.Path]::IsPathRooted($Path)) {
    $Path = Join-Path $repoRoot $Path
}

Write-Output "Running PSScriptAnalyzer on: $Path"

# Locate repo-level settings file if present
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$settingsFile = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
if (Test-Path $settingsFile) {
    Write-Output "Using settings file: $settingsFile"
}
else {
    $settingsFile = $null
}


# Ensure module is available in current user scope
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Output "PSScriptAnalyzer not found. Installing to CurrentUser scope..."
    try {
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to install PSScriptAnalyzer: $($_.Exception.Message)"
        exit 2
    }
}


# Import the highest-version available PSScriptAnalyzer module (prefer user-installed)
$available = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending
if ($available -and $available.Count -gt 0) {
    # Prefer modules that are not inside the repository root (i.e., user/system-installed)
    $external = $available | Where-Object { $_.Path -and ($_.Path -notlike "$repoRoot*") }
    if ($external -and $external.Count -gt 0) {
        $moduleToUse = $external[0]
    }
    else {
        # Fall back to the highest-version module (may be bundled in repo)
        $moduleToUse = $available[0]
    }
    Write-Output "Importing PSScriptAnalyzer module from: $($moduleToUse.Path) (version $($moduleToUse.Version))"
    Import-Module -Name $moduleToUse.Path -Force -ErrorAction Stop
}
else {
    Write-Output "PSScriptAnalyzer module not found after install; aborting"
    exit 2
}

$excludeRules = @()

# Detect whether the installed Invoke-ScriptAnalyzer supports -SettingsPath
$invokeCmd = Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue
$supportsSettings = $false
if ($invokeCmd) {
    try {
        $supportsSettings = ($invokeCmd.Parameters.Keys -contains 'SettingsPath')
    }
    catch {
        $supportsSettings = $false
    }
}

# If the module doesn't support -SettingsPath, try to read ExcludeRules from
# the repo settings and apply them manually to the results.
if ($settingsFile -and -not $supportsSettings) {
    try {
        # Prefer Import-PowerShellDataFile when available (PowerShell 6+)
        if (Get-Command Import-PowerShellDataFile -ErrorAction SilentlyContinue) {
            $settings = Import-PowerShellDataFile -Path $settingsFile
        }
        else {
            # Fallback: read content and evaluate as literal hashtable
            $settings = Invoke-Expression -Command (Get-Content -Path $settingsFile -Raw)
        }

        if ($settings.ContainsKey('ExcludeRules')) {
            $excludeRules = @($settings['ExcludeRules']) | Where-Object { $_ }
            Write-Output "Applying ExcludeRules from settings: $($excludeRules -join ', ')"
        }
    }
    catch {
        Write-Output "Warning: failed to parse settings file for manual excludes: $($_.Exception.Message)"
        $excludeRules = @()
    }
}

$errors = @()
Get-ChildItem -Path $Path -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Analyzing $file"
    # Use the repository settings file if available so ExcludeRules are applied.
    if ($settingsFile -and $supportsSettings) {
        $results = Invoke-ScriptAnalyzer -Path $file -Recurse -Severity Error -SettingsPath $settingsFile
    }
    elseif ($settingsFile -and -not $supportsSettings) {
        $results = Invoke-ScriptAnalyzer -Path $file -Recurse -Severity Error
        # Manually filter out excluded rules
        if ($excludeRules.Count -gt 0) {
            $results = $results | Where-Object { $excludeRules -notcontains $_.RuleName }
        }
    }
    else {
        $results = Invoke-ScriptAnalyzer -Path $file -Recurse -Severity Error
    }
    if ($results) {
        # If we have manual excludes, filter them out when -SettingsPath isn't supported
        if ($excludeRules.Count -gt 0 -and -not $supportsSettings) {
            $filtered = $results | Where-Object { $excludeRules -notcontains $_.RuleName }
        }
        else {
            $filtered = $results
        }

        if ($filtered) {
            # Normalize filename (some analyzer versions populate ScriptName instead of FileName)
            $out = $filtered | ForEach-Object {
                $fn = if ($_.PSObject.Properties.Match('FileName') -and $_.FileName) { $_.FileName }
                elseif ($_.PSObject.Properties.Match('ScriptName') -and $_.ScriptName) { $_.ScriptName }
                elseif ($_.PSObject.Properties.Match('Path') -and $_.Path) { $_.Path }
                else { $file }
                [PSCustomObject]@{
                    File     = $fn
                    RuleName = $_.RuleName
                    Severity = $_.Severity
                    Line     = $_.Line
                    Message  = $_.Message
                }
            }
            $out | Format-Table File, RuleName, Severity, Line, Message -AutoSize
            $errors += $filtered
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Error "$($errors.Count) linter issues found"
    exit 1
}

Write-Output "PSScriptAnalyzer: no issues found"
exit 0
