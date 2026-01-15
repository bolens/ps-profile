# ===============================================
# Text comparison and diff utilities
# ===============================================

<#
.SYNOPSIS
    Initializes text comparison utility functions.
.DESCRIPTION
    Sets up internal functions for comparing text files and showing differences.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Diff {
    # Text Comparer/Diff Tool
    Set-Item -Path Function:Global:_Compare-TextFiles -Value {
        param([string]$File1, [string]$File2)
        try {
            if (-not ($File1 -and -not [string]::IsNullOrWhiteSpace($File1) -and (Test-Path -LiteralPath $File1))) { throw "File not found: $File1" }
            if (-not ($File2 -and -not [string]::IsNullOrWhiteSpace($File2) -and (Test-Path -LiteralPath $File2))) { throw "File not found: $File2" }
            $content1 = Get-Content -LiteralPath $File1 -Raw
            $content2 = Get-Content -LiteralPath $File2 -Raw
            if ($content1 -eq $content2) {
                Write-Host "Files are identical." -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "Files are different." -ForegroundColor Yellow
                # Use diff if available, otherwise show basic comparison
                if (Get-Command diff -ErrorAction SilentlyContinue) {
                    & diff $File1 $File2
                }
                else {
                    $lines1 = Get-Content -LiteralPath $File1
                    $lines2 = Get-Content -LiteralPath $File2
                    $maxLines = [Math]::Max($lines1.Count, $lines2.Count)
                    for ($i = 0; $i -lt $maxLines; $i++) {
                        $line1 = if ($i -lt $lines1.Count) { $lines1[$i] } else { '' }
                        $line2 = if ($i -lt $lines2.Count) { $lines2[$i] } else { '' }
                        if ($line1 -ne $line2) {
                            Write-Host "Line $($i + 1):" -ForegroundColor Cyan
                            Write-Host "  File1: $line1" -ForegroundColor Red
                            Write-Host "  File2: $line2" -ForegroundColor Green
                        }
                    }
                }
                return $false
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.diff.compare' -Context @{
                    file1 = $File1
                    file2 = $File2
                }
            }
            else {
                Write-Error "Failed to compare files: $_"
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Compares two text files and shows differences.
.DESCRIPTION
    Compares two text files and displays differences. Uses diff command if available,
    otherwise shows a line-by-line comparison.
.PARAMETER File1
    Path to the first file.
.PARAMETER File2
    Path to the second file.
.EXAMPLE
    Compare-TextFiles -File1 "file1.txt" -File2 "file2.txt"
    Compares the two files and shows differences.
.OUTPUTS
    System.Boolean
    Returns $true if files are identical, $false if different.
#>
function Compare-TextFiles {
    param([string]$File1, [string]$File2)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Compare-TextFiles @PSBoundParameters
}
Set-Alias -Name diff-files -Value Compare-TextFiles -ErrorAction SilentlyContinue
Set-Alias -Name compare-files -Value Compare-TextFiles -ErrorAction SilentlyContinue

