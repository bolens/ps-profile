<#
scripts/utils/run-format.ps1

.SYNOPSIS
    Formats PowerShell code using PSScriptAnalyzer for consistent styling.

.DESCRIPTION
    Formats PowerShell code using PSScriptAnalyzer's Invoke-Formatter for consistent styling.
    By default, formats all PowerShell files in the profile.d directory. Preserves original
    line endings (CRLF or LF) in the formatted output.

.PARAMETER Path
    The path to format. Defaults to profile.d directory relative to repository root.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1

    Formats all PowerShell files in the profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1 -Path scripts

    Formats all PowerShell files in the scripts directory.
#>

param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null
)

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Default to profile.d relative to the repository root
try {
    $defaultPath = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    $Path = Resolve-DefaultPath -Path $Path -DefaultPath $defaultPath -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Running PSScriptAnalyzer formatter on: $Path"

# Ensure PSScriptAnalyzer is available (includes formatting capabilities)
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Compile regex pattern once for CRLF detection
$crlfRegex = [regex]::new("`r`n", [System.Text.RegularExpressions.RegexOptions]::Compiled)

$filesFormatted = 0
# Use List for better performance than array concatenation
$errors = [System.Collections.Generic.List[PSCustomObject]]::new()

# Get PowerShell scripts using helper function
$scripts = Get-PowerShellScripts -Path $Path

# Process files sequentially to avoid serialization issues during formatting
Write-ScriptMessage -Message "Formatting $($scripts.Count) file(s)..."

foreach ($scriptFile in $scripts) {
    $file = $scriptFile.FullName

    try {
        # Skip if file disappeared since listing
        if (-not (Test-Path -Path $file)) {
            Write-ScriptMessage -Message "Skipping missing file: $file"
            continue
        }

        # Read the original content to detect line endings
        $originalContent = Get-Content -Path $file -Raw -ErrorAction Stop

        # Handle empty files
        if ([string]::IsNullOrEmpty($originalContent)) {
            Write-ScriptMessage -Message "Skipping empty file: $file"
            continue
        }

        $hasCRLF = $crlfRegex.IsMatch($originalContent)

        # Use Invoke-Formatter from PSScriptAnalyzer to format the file
        $formattedContent = Invoke-Formatter -ScriptDefinition $originalContent -ErrorAction Stop

        # Trim trailing whitespace and ensure consistent line endings
        $formattedContent = $formattedContent.TrimEnd()
        if ($hasCRLF) {
            $formattedContent += "`r`n"
        }
        else {
            $formattedContent += "`n"
        }

        $formattedContent | Set-Content -Path $file -Encoding UTF8 -NoNewline -ErrorAction Stop

        $filesFormatted++
        Write-ScriptMessage -Message "Formatted $file"
    }
    catch {
        $errors.Add([PSCustomObject]@{
                File  = $file
                Error = $_.Exception.Message
            })
        Write-ScriptMessage -Message ("Failed to format {0}: {1}" -f $file, $_.Exception.Message) -IsWarning
    }
}

Write-ScriptMessage -Message "Formatted $filesFormatted file(s)"

if ($errors.Count -gt 0) {
    $errorDetails = $errors | ForEach-Object { "  $($_.File): $($_.Error)" }
    $errorMessage = "Failed to format $($errors.Count) file(s):`n$($errorDetails -join "`n")"
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message $errorMessage
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "PSScriptAnalyzer: all files formatted successfully"

