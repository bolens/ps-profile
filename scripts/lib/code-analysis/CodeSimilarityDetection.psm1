<#
scripts/lib/CodeSimilarityDetection.psm1

.SYNOPSIS
    Code similarity detection utilities.

.DESCRIPTION
    Provides functions for detecting similar code blocks across PowerShell scripts.
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import dependencies (modules used for file operations, string comparison, AST parsing, and collections)
# FileSystem is in file/ subdirectory, StringSimilarity and Collections are in utilities/ subdirectory
# AstParsing is in code-analysis/ subdirectory (same as this module), FileContent is in file/ subdirectory
$fileSystemModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'file' 'FileSystem.psm1'
$stringSimilarityModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utilities' 'StringSimilarity.psm1'
$astParsingModulePath = Join-Path $PSScriptRoot 'AstParsing.psm1'
$fileContentModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'file' 'FileContent.psm1'
$collectionsModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utilities' 'Collections.psm1'

if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $stringSimilarityModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $astParsingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $collectionsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($fileSystemModulePath -and -not [string]::IsNullOrWhiteSpace($fileSystemModulePath) -and (Test-Path -LiteralPath $fileSystemModulePath)) {
        Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($stringSimilarityModulePath -and -not [string]::IsNullOrWhiteSpace($stringSimilarityModulePath) -and (Test-Path -LiteralPath $stringSimilarityModulePath)) {
        Import-Module $stringSimilarityModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($astParsingModulePath -and -not [string]::IsNullOrWhiteSpace($astParsingModulePath) -and (Test-Path -LiteralPath $astParsingModulePath)) {
        Import-Module $astParsingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($fileContentModulePath -and -not [string]::IsNullOrWhiteSpace($fileContentModulePath) -and (Test-Path -LiteralPath $fileContentModulePath)) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($collectionsModulePath -and -not [string]::IsNullOrWhiteSpace($collectionsModulePath) -and (Test-Path -LiteralPath $collectionsModulePath)) {
        Import-Module $collectionsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Detects similar code blocks across PowerShell scripts.

.DESCRIPTION
    Analyzes PowerShell scripts to find similar code blocks beyond just function names.
    Uses AST comparison and text similarity to detect duplicated or similar code patterns.
    Returns similar code blocks with similarity scores.

.PARAMETER Path
    Path to analyze (file or directory).

.PARAMETER Recurse
    If specified, recursively searches subdirectories.

.PARAMETER MinSimilarity
    Minimum similarity threshold (0-1). Default: 0.7 (70%).

.PARAMETER MinBlockSize
    Minimum number of lines for a code block to be considered. Default: 5.

.OUTPUTS
    PSCustomObject array with similar code blocks and their similarity scores.

.EXAMPLE
    $similar = Get-CodeSimilarity -Path "scripts" -Recurse -MinSimilarity 0.8
    foreach ($match in $similar) {
        Write-Output "$($match.File1) and $($match.File2) are $($match.SimilarityPercent)% similar"
    }
#>
function Get-CodeSimilarity {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse,

        [ValidateRange(0, 1)]
        [double]$MinSimilarity = 0.7,

        [int]$MinBlockSize = 5
    )

    # Ensure FileSystem module is loaded
    if (-not (Get-Command Get-PowerShellScripts -ErrorAction SilentlyContinue)) {
        # Try to load FileSystem module if not available
        $fileSystemModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'file' 'FileSystem.psm1'
        if ($fileSystemModulePath -and (Test-Path -LiteralPath $fileSystemModulePath)) {
            Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        
        # Check again after attempting to load
        if (-not (Get-Command Get-PowerShellScripts -ErrorAction SilentlyContinue)) {
            throw "Get-PowerShellScripts function not available. FileSystem module may not be loaded."
        }
    }

    $scripts = Get-PowerShellScripts -Path $Path -Recurse:$Recurse
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Host "  [code-similarity.compare] Found $($scripts.Count) scripts for similarity analysis" -ForegroundColor DarkGray
    }

    if ($null -eq $scripts -or $scripts.Count -lt 2) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Need at least 2 scripts to compare similarity" -OperationName 'code-similarity.compare' -Context @{
                script_count = if ($scripts) { $scripts.Count } else { 0 }
                path         = $Path
            } -Code 'InsufficientScripts'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Warning "[code-similarity.compare] Need at least 2 scripts to compare similarity"
                }
                # Level 3: Log detailed insufficient scripts information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[code-similarity.compare] Insufficient scripts details - ScriptCount: $(if ($scripts) { $scripts.Count } else { 0 }), Path: $Path, Recurse: $Recurse"
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Need at least 2 scripts to compare similarity" -OperationName 'code-similarity.compare' -Context @{
                        # Technical context
                        script_count = if ($scripts) { $scripts.Count } else { 0 }
                        path         = $Path
                        # Operation context
                        recurse      = $Recurse
                        # Invocation context
                        FunctionName = 'Get-CodeSimilarity'
                    } -Code 'InsufficientScripts'
                }
                else {
                    Write-Warning "[code-similarity.compare] Need at least 2 scripts to compare similarity"
                }
            }
        }
        return [object[]]::new(0)
    }

    # Use Collections module for better performance
    $similarBlocks = if (Get-Command New-ObjectList -ErrorAction SilentlyContinue) {
        $list = New-ObjectList
        if ($null -eq $list) {
            [System.Collections.Generic.List[PSCustomObject]]::new()
        }
        else {
            $list
        }
    }
    else {
        [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    
    # Ensure similarBlocks is initialized (defensive check)
    if ($null -eq $similarBlocks) {
        $similarBlocks = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    # Extract code blocks from each script
    $scriptBlocks = [System.Collections.Generic.Dictionary[string, object[]]]::new()

    foreach ($script in $scripts) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [code-similarity.extract-blocks] Extracting blocks from: $($script.FullName)" -ForegroundColor DarkGray
        }
        
        try {
            # Use FileContent module if available
            $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
                Read-FileContent -Path $script.FullName -ErrorAction Stop
            }
            else {
                Get-Content -Path $script.FullName -Raw -ErrorAction Stop
            }
            
            # Use AstParsing module if available
            $ast = $null
            $functions = @()
            if (Get-Command Get-PowerShellAst -ErrorAction SilentlyContinue) {
                try {
                    $ast = Get-PowerShellAst -Path $script.FullName
                    if ($null -ne $ast) {
                        $functions = Get-FunctionsFromAst -Ast $ast
                    }
                }
                catch {
                    # Parsing failed, will fall back to file-level comparison
                    $ast = $null
                    $functions = @()
                }
            }
            
            # Fallback: use PowerShell's built-in parser if AST module unavailable
            if ($null -eq $ast) {
                try {
                    $parseErrors = $null
                    $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$parseErrors, [ref]$null)
                    if ($parseErrors -and $parseErrors.Count -gt 0) {
                        # Parsing errors detected, will fall back to file-level text comparison
                        $ast = $null
                        $functions = @()
                    }
                    elseif ($null -ne $ast) {
                        # Extract function definitions from AST
                        $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
                    }
                }
                catch {
                    # Parsing completely failed, will fall back to file-level text comparison
                    $ast = $null
                    $functions = @()
                }
            }

            # Extract code blocks from functions (using optimized collections if available)
            $blocks = if (Get-Command New-TypedList -ErrorAction SilentlyContinue) {
                New-TypedList -Type "object"
            }
            else {
                [System.Collections.Generic.List[object]]::new()
            }
            foreach ($func in $functions) {
                if ($null -eq $func -or $null -eq $func.Body -or $null -eq $func.Body.Extent) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Invalid function AST structure" -OperationName 'code-similarity.extract-blocks' -Context @{
                            script_path = $script.FullName
                        } -Code 'InvalidAstStructure'
                    }
                    else {
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                            if ($debugLevel -ge 2) {
                                Write-Warning "[code-similarity.extract-blocks] Failed to analyze $($script.FullName): Invalid function AST structure"
                            }
                            # Level 3: Log detailed invalid AST structure information
                            if ($debugLevel -ge 3) {
                                Write-Host "  [code-similarity.extract-blocks] Invalid AST structure details - ScriptPath: $($script.FullName), FunctionName: $(if ($func) { $func.Name } else { 'unknown' })" -ForegroundColor DarkGray
                            }
                        }
                        else {
                            # Always log warnings even if debug is off
                            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                Write-StructuredWarning -Message "Invalid function AST structure" -OperationName 'code-similarity.extract-blocks' -Context @{
                                    # Technical context
                                    script_path   = $script.FullName
                                    script_name   = $script.Name
                                    function_name = if ($func) { $func.Name } else { 'unknown' }
                                    # Invocation context
                                    FunctionName  = 'Get-CodeSimilarity'
                                } -Code 'InvalidAstStructure'
                            }
                            else {
                                Write-Warning "[code-similarity.extract-blocks] Failed to analyze $($script.FullName): Invalid function AST structure"
                            }
                        }
                    }
                    continue
                }
                
                $funcBody = $func.Body.Extent.Text
                $lineCount = ($funcBody -split "`n").Count

                # Only process functions that meet minimum size threshold
                if ($lineCount -ge $MinBlockSize) {
                    # Normalize code for comparison: remove whitespace, comments, and normalize variable/string literals
                    # This allows detection of similar code patterns even with different variable names
                    $normalized = $funcBody -replace '\s+', ' ' `
                        -replace '#.*', '' `
                        -replace '\$[a-zA-Z_][a-zA-Z0-9_]*', '$VAR' `
                        -replace '"[^"]*"', '""' `
                        -replace "'[^']*'", "''"

                    $blocks.Add([PSCustomObject]@{
                            Type       = 'Function'
                            Name       = $func.Name
                            Content    = $funcBody
                            Normalized = $normalized
                            LineCount  = $lineCount
                            StartLine  = $func.Extent.StartLineNumber
                            EndLine    = $func.Extent.EndLineNumber
                        })
                }
            }

            # Extract if/else blocks, try/catch blocks, etc.
            $ifStatements = if ($null -ne $ast) {
                $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.IfStatementAst] }, $true)
            }
            else {
                @()
            }
            foreach ($ifStmt in $ifStatements) {
                if ($null -eq $ifStmt -or $null -eq $ifStmt.Extent) {
                    continue
                }
                
                $blockText = $ifStmt.Extent.Text
                $lineCount = ($blockText -split "`n").Count

                if ($lineCount -lt $MinBlockSize) {
                    continue
                }

                $normalized = $blockText -replace '\s+', ' ' `
                    -replace '#.*', '' `
                    -replace '\$[a-zA-Z_][a-zA-Z0-9_]*', '$VAR' `
                    -replace '"[^"]*"', '""' `
                    -replace "'[^']*'", "''"

                $blocks.Add([PSCustomObject]@{
                        Type       = 'IfStatement'
                        Name       = "If-$($ifStmt.Extent.StartLineNumber)"
                        Content    = $blockText
                        Normalized = $normalized
                        LineCount  = $lineCount
                        StartLine  = $ifStmt.Extent.StartLineNumber
                        EndLine    = $ifStmt.Extent.EndLineNumber
                    })
            }

            if ($blocks.Count -gt 0) {
                $scriptBlocks[$script.FullName] = $blocks.ToArray()
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [code-similarity.extract-blocks] Extracted $($blocks.Count) blocks from $($script.Name)" -ForegroundColor DarkGray
                }
            }
            else {
                $lineCount = ($content -split "`n").Count
                if ($lineCount -gt 0) {
                    $normalized = $content -replace '\s+', ' ' `
                        -replace '#.*', '' `
                        -replace '\$[a-zA-Z_][a-zA-Z0-9_]*', '$VAR' `
                        -replace '"[^"]*"', '""' `
                        -replace "'[^']*'", "''"

                    $scriptBlocks[$script.FullName] = @([PSCustomObject]@{
                            Type       = 'File'
                            Name       = $script.Name
                            Content    = $content
                            Normalized = $normalized
                            LineCount  = $lineCount
                            StartLine  = 1
                            EndLine    = $lineCount
                        })
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to analyze script" -OperationName 'code-similarity.extract-blocks' -Context @{
                    script_path   = $script.FullName
                    error_message = $_.Exception.Message
                } -Code 'ScriptAnalysisFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[code-similarity.extract-blocks] Failed to analyze $($script.FullName): $($_.Exception.Message)"
                }
            }
        }
    }

    # Compare blocks for similarity
    if ($scriptBlocks.Count -lt 2) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [code-similarity.compare] Need at least 2 scripts with blocks to compare similarity" -ForegroundColor DarkGray
        }
        return [object[]]::new(0)
    }
    
    $scriptPaths = $scriptBlocks.Keys | Sort-Object
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [code-similarity.compare] Comparing $($scriptPaths.Count) scripts for similarity" -ForegroundColor DarkGray
    }
    
    for ($i = 0; $i -lt $scriptPaths.Count; $i++) {
        for ($j = $i + 1; $j -lt $scriptPaths.Count; $j++) {
            $file1 = $scriptPaths[$i]
            $file2 = $scriptPaths[$j]
            $blocks1 = $scriptBlocks[$file1]
            $blocks2 = $scriptBlocks[$file2]
            
            # Skip if either file has no blocks
            if ($null -eq $blocks1 -or $blocks1.Count -eq 0) { continue }
            if ($null -eq $blocks2 -or $blocks2.Count -eq 0) { continue }

            foreach ($block1 in $blocks1) {
                foreach ($block2 in $blocks2) {
                    # Skip if blocks are null
                    if ($null -eq $block1 -or $null -eq $block2) {
                        continue
                    }
                    
                    # Skip if blocks don't have normalized content
                    if ([string]::IsNullOrWhiteSpace($block1.Normalized) -or [string]::IsNullOrWhiteSpace($block2.Normalized)) {
                        continue
                    }
                    
                    # Calculate similarity using normalized content
                    # Check if Get-StringSimilarity is available, otherwise use simple comparison
                    $similarity = 0.0
                    if (Get-Command Get-StringSimilarity -ErrorAction SilentlyContinue) {
                        try {
                            $similarity = Get-StringSimilarity -String1 $block1.Normalized -String2 $block2.Normalized
                        }
                        catch {
                            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                Write-StructuredWarning -Message "Failed to calculate similarity" -OperationName 'code-similarity.calculate' -Context @{
                                    file1         = $file1
                                    file2         = $file2
                                    block1_name   = $block1.Name
                                    block2_name   = $block2.Name
                                    error_message = $_.Exception.Message
                                } -Code 'SimilarityCalculationFailed'
                            }
                            else {
                                $debugLevel = 0
                                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                                    if ($debugLevel -ge 2) {
                                        Write-Warning "[code-similarity.calculate] Failed to calculate similarity: $($_.Exception.Message)"
                                    }
                                    # Level 3: Log detailed similarity calculation error information
                                    if ($debugLevel -ge 3) {
                                        Write-Host "  [code-similarity.calculate] Similarity calculation error details - File1: $file1, File2: $file2, Block1Name: $($block1.Name), Block2Name: $($block2.Name), Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                                    }
                                }
                                else {
                                    # Always log warnings even if debug is off
                                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                        Write-StructuredWarning -Message "Failed to calculate similarity" -OperationName 'code-similarity.calculate' -Context @{
                                            # Technical context
                                            file1          = $file1
                                            file2          = $file2
                                            block1_name    = $block1.Name
                                            block2_name    = $block2.Name
                                            # Error context
                                            error_message  = $_.Exception.Message
                                            ErrorType      = $_.Exception.GetType().FullName
                                            # Operation context
                                            min_similarity = $MinSimilarity
                                            # Invocation context
                                            FunctionName   = 'Get-CodeSimilarity'
                                        } -Code 'SimilarityCalculationFailed'
                                    }
                                    else {
                                        Write-Warning "[code-similarity.calculate] Failed to calculate similarity: $($_.Exception.Message)"
                                    }
                                }
                            }
                            # Fall back to simple string comparison
                            if ($block1.Normalized -eq $block2.Normalized) {
                                $similarity = 1.0
                            }
                            else {
                                continue
                            }
                        }
                    }
                    else {
                        # Fallback: simple string equality check
                        if ($block1.Normalized -eq $block2.Normalized) {
                            $similarity = 1.0
                        }
                        else {
                            # Simple length-based similarity as fallback
                            $len1 = $block1.Normalized.Length
                            $len2 = $block2.Normalized.Length
                            if ($len1 -eq 0 -or $len2 -eq 0) {
                                continue
                            }
                            $maxLen = [Math]::Max($len1, $len2)
                            $minLen = [Math]::Min($len1, $len2)
                            $similarity = $minLen / $maxLen
                        }
                    }

                    if ($similarity -ge $MinSimilarity) {
                        # Ensure similarBlocks is initialized before adding
                        if ($null -eq $similarBlocks) {
                            $similarBlocks = [System.Collections.Generic.List[PSCustomObject]]::new()
                        }
                        
                        # Safely get property values with null checks (check object first, then property)
                        $block1StartLine = if ($null -ne $block1) { try { if ($null -ne $block1.StartLine) { [int]$block1.StartLine } else { $null } } catch { $null } } else { $null }
                        $block1EndLine = if ($null -ne $block1) { try { if ($null -ne $block1.EndLine) { [int]$block1.EndLine } else { $null } } catch { $null } } else { $null }
                        $block2StartLine = if ($null -ne $block2) { try { if ($null -ne $block2.StartLine) { [int]$block2.StartLine } else { $null } } catch { $null } } else { $null }
                        $block2EndLine = if ($null -ne $block2) { try { if ($null -ne $block2.EndLine) { [int]$block2.EndLine } else { $null } } catch { $null } } else { $null }
                        $block1LineCount = if ($null -ne $block1) { try { if ($null -ne $block1.LineCount) { [int]$block1.LineCount } else { 0 } } catch { 0 } } else { 0 }
                        $block2LineCount = if ($null -ne $block2) { try { if ($null -ne $block2.LineCount) { [int]$block2.LineCount } else { 0 } } catch { 0 } } else { 0 }
                        
                        # Build line strings safely
                        $block1LinesStr = if ($null -ne $block1StartLine -and $null -ne $block1EndLine) { "$block1StartLine-$block1EndLine" } else { "N/A" }
                        $block2LinesStr = if ($null -ne $block2StartLine -and $null -ne $block2EndLine) { "$block2StartLine-$block2EndLine" } else { "N/A" }
                        
                        # Safely get block properties
                        $block1Type = if ($null -ne $block1) { try { $block1.Type } catch { "Unknown" } } else { "Unknown" }
                        $block1Name = if ($null -ne $block1) { try { $block1.Name } catch { "Unknown" } } else { "Unknown" }
                        $block2Type = if ($null -ne $block2) { try { $block2.Type } catch { "Unknown" } } else { "Unknown" }
                        $block2Name = if ($null -ne $block2) { try { $block2.Name } catch { "Unknown" } } else { "Unknown" }
                        
                        $similarBlocks.Add([PSCustomObject]@{
                                File1             = Split-Path -Leaf $file1
                                File1Path         = $file1
                                File2             = Split-Path -Leaf $file2
                                File2Path         = $file2
                                Block1Type        = $block1Type
                                Block1Name        = $block1Name
                                Block2Type        = $block2Type
                                Block2Name        = $block2Name
                                Similarity        = $similarity
                                SimilarityPercent = [math]::Round($similarity * 100, 2)
                                Block1Lines       = $block1LinesStr
                                Block2Lines       = $block2LinesStr
                                Block1LineCount   = $block1LineCount
                                Block2LineCount   = $block2LineCount
                            })
                    }
                }
            }
        }
    }

    if ($null -eq $similarBlocks -or $similarBlocks.Count -eq 0) {
        return [object[]]::new(0)
    }
    
    $results = [object[]]($similarBlocks.ToArray() | Sort-Object -Property Similarity -Descending)
    return , $results
}

Export-ModuleMember -Function Get-CodeSimilarity
