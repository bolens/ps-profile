<#
scripts/utils/run-format.ps1

.SYNOPSIS
    Formats PowerShell code using PSScriptAnalyzer for consistent styling.

.DESCRIPTION
    Formats PowerShell code using PSScriptAnalyzer's Invoke-Formatter for consistent styling.
    By default, formats all PowerShell files in the profile.d directory. Normalizes
    line endings to LF (Unix-style) to match Git's behavior and avoid line ending warnings.

.PARAMETER Path
    The path to format. Defaults to profile.d directory relative to repository root.

.PARAMETER DryRun
    If specified, shows what would be formatted without actually modifying files.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1

    Formats all PowerShell files in the profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1 -Path scripts

    Formats all PowerShell files in the scripts directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1 -DryRun

    Shows what files would be formatted without actually modifying them.
#>

param(
    [ValidateScript({
            if ($_ -and -not [string]::IsNullOrWhiteSpace($_) -and -not (Test-Path -LiteralPath $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null,

    [switch]$DryRun
)

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and -not [string]::IsNullOrWhiteSpace($pathResolutionPath) -and -not (Test-Path -LiteralPath $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Default to profile.d relative to the repository root
try {
    $defaultPath = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    $Path = Resolve-DefaultPath -Path $Path -DefaultPath $defaultPath -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[format] Starting code formatting"
    Write-Verbose "[format] Target path: $Path"
    Write-Verbose "[format] Dry run mode: $DryRun"
}

Write-ScriptMessage -Message "Running PSScriptAnalyzer formatter on: $Path"

# Ensure PSScriptAnalyzer is available (includes formatting capabilities)
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Normalize line endings to LF (Unix-style) to match Git's behavior

$filesFormatted = 0
# Use List for better performance than array concatenation
$errors = [System.Collections.Generic.List[PSCustomObject]]::new()

# Get PowerShell scripts using helper function
$scripts = Get-PowerShellScripts -Path $Path

# Level 2: File list details
if ($debugLevel -ge 2) {
    Write-Verbose "[format] Found $($scripts.Count) PowerShell script(s) to process"
}

# Process files sequentially to avoid serialization issues during formatting
if ($DryRun) {
    Write-ScriptMessage -Message "DRY RUN MODE: Would format $($scripts.Count) file(s)..." -ForegroundColor Yellow
}
else {
    Write-ScriptMessage -Message "Formatting $($scripts.Count) file(s)..."
}

$formatStartTime = Get-Date
foreach ($scriptFile in $scripts) {
    $file = $scriptFile.FullName

    try {
        # Skip if file disappeared since listing
        if (-not (Test-Path -Path $file)) {
            Write-ScriptMessage -Message "Skipping missing file: $file"
            continue
        }

        # Read the original content
        $originalContent = Get-Content -Path $file -Raw -ErrorAction Stop

        # Handle empty files
        if ([string]::IsNullOrEmpty($originalContent)) {
            Write-ScriptMessage -Message "Skipping empty file: $file"
            continue
        }

        # Normalize line endings to LF first (replace CRLF with LF)
        $normalizedContent = $originalContent -replace "`r`n", "`n"

        # Use Invoke-Formatter from PSScriptAnalyzer to format the file
        $formattedContent = Invoke-Formatter -ScriptDefinition $normalizedContent -ErrorAction Stop

        # Trim trailing whitespace and ensure LF line ending
        $formattedContent = $formattedContent.TrimEnd() + "`n"

        if ($DryRun) {
            # Check if content would change
            if ($originalContent -ne $formattedContent) {
                Write-ScriptMessage -Message "[DRY RUN] Would format: $file" -ForegroundColor Yellow
                $filesFormatted++
            }
            else {
                Write-ScriptMessage -Message "[DRY RUN] No changes needed: $file" -ForegroundColor Gray
            }
        }
        else {
            $formattedContent | Set-Content -Path $file -Encoding UTF8 -NoNewline -ErrorAction Stop
            $filesFormatted++
            Write-ScriptMessage -Message "Formatted $file"
            
            # Level 2: Individual file formatting
            if ($debugLevel -ge 2) {
                Write-Verbose "[format] Formatted file: $file"
            }
        }
    }
    catch {
        $errors.Add([PSCustomObject]@{
                File  = $file
                Error = $_.Exception.Message
            })
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to format file" -OperationName 'format.file' -Context @{
                file = $file
            } -Code 'FormatFileFailed'
        }
        else {
            Write-ScriptMessage -Message ("Failed to format {0}: {1}" -f $file, $_.Exception.Message) -IsWarning
        }
    }
}

$formatDuration = ((Get-Date) - $formatStartTime).TotalMilliseconds

# Level 2: Formatting timing
if ($debugLevel -ge 2) {
    Write-Verbose "[format] Formatting completed in ${formatDuration}ms"
    Write-Verbose "[format] Files formatted: $filesFormatted, Errors: $($errors.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgFormatTime = if ($scripts.Count -gt 0) { $formatDuration / $scripts.Count } else { 0 }
    Write-Host "  [format] Performance - Duration: ${formatDuration}ms, Avg per file: ${avgFormatTime}ms, Files: $($scripts.Count), Formatted: $filesFormatted" -ForegroundColor DarkGray
}

if ($DryRun) {
    Write-ScriptMessage -Message "[DRY RUN] Would format $filesFormatted file(s)" -ForegroundColor Yellow
    Write-ScriptMessage -Message "Run without -DryRun to apply changes." -ForegroundColor Yellow
}
else {
    Write-ScriptMessage -Message "Formatted $filesFormatted file(s)"
}

if ($errors.Count -gt 0) {
    $errorDetails = $errors | ForEach-Object { "  $($_.File): $($_.Error)" }
    $errorMessage = "Failed to format $($errors.Count) file(s):`n$($errorDetails -join "`n")"
    
    # Allow partial success - if we formatted at least some files, report warning but don't fail
    if ($filesFormatted -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some files failed to format" -OperationName 'format.batch' -Context @{
                formatted_count = $filesFormatted
                failed_count = $errors.Count
                total_files = $scripts.Count
            } -Code 'FormatPartialFailure'
        }
        else {
            Write-ScriptMessage -Message "Warning: $errorMessage" -IsWarning
        }
        # Continue with success if we formatted at least some files
        if ($DryRun) {
            Exit-WithCode -ExitCode [ExitCode]::Success -Message "DRY RUN: Would format $filesFormatted file(s) (with $($errors.Count) failures). Run without -DryRun to apply changes."
        }
        else {
            Exit-WithCode -ExitCode [ExitCode]::Success -Message "PSScriptAnalyzer: formatted $filesFormatted file(s) (with $($errors.Count) failures)"
        }
    }
    else {
        # All files failed - this is a real failure
        Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message $errorMessage
    }
}

if ($DryRun) {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "DRY RUN: Would format $filesFormatted file(s). Run without -DryRun to apply changes."
}
else {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "PSScriptAnalyzer: all files formatted successfully"
}

