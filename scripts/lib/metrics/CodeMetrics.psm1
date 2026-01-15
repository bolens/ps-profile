<#
scripts/lib/CodeMetrics.psm1

.SYNOPSIS
    Code metrics collection utilities.

.DESCRIPTION
    Provides functions for analyzing PowerShell scripts and collecting metrics
    like line count, function count, complexity, and code duplication detection.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import dependencies
# FileSystem is in file/ subdirectory, AstParsing is in code-analysis/ subdirectory
# FileContent is in file/ subdirectory, Collections is in utilities/ subdirectory
$fileSystemModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'file' 'FileSystem.psm1'
$astParsingModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'code-analysis' 'AstParsing.psm1'
$fileContentModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'file' 'FileContent.psm1'
$collectionsModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utilities' 'Collections.psm1'

if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $astParsingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $collectionsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($fileSystemModulePath -and -not [string]::IsNullOrWhiteSpace($fileSystemModulePath) -and (Test-Path -LiteralPath $fileSystemModulePath)) {
        Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
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
    Converts a list to a non-null array for FileMetrics property.
    
.DESCRIPTION
    Helper function to ensure FileMetrics is always a non-null array,
    even when the input is null or empty.
    
.PARAMETER InputList
    The input list to convert to an array.
    
.OUTPUTS
    System.Array - Always returns a non-null array (may be empty).
#>
function ConvertTo-FileMetricsArray {
    param([object]$InputList)
    
    if ($null -eq $InputList) {
        $empty = [object[]]@()
        Write-Output -NoEnumerate $empty
        return
    }
    
    if ($InputList -is [System.Collections.IList]) {
        if ($InputList.Count -eq 0) {
            $empty = [object[]]@()
            Write-Output -NoEnumerate $empty
            return
        }
        $result = [object[]]::new($InputList.Count)
        for ($i = 0; $i -lt $InputList.Count; $i++) {
            $result[$i] = $InputList[$i]
        }
        Write-Output -NoEnumerate $result
        return
    }
    
    # If it's already an array, return it as-is
    if ($InputList -is [System.Array]) {
        Write-Output -NoEnumerate $InputList
        return
    }
    
    # Otherwise, wrap it in an array
    $wrapped = [object[]]@($InputList)
    Write-Output -NoEnumerate $wrapped
    return
}

<#
.SYNOPSIS
    Collects code metrics for PowerShell scripts.

.DESCRIPTION
    Analyzes PowerShell scripts and collects metrics like line count, function count,
    complexity, and other code quality metrics.

.PARAMETER Path
    Path to script file or directory to analyze.

.PARAMETER Recurse
    If specified, analyzes scripts recursively in subdirectories.

.OUTPUTS
    PSCustomObject with code metrics including line count, function count, complexity, etc.
    Expected properties: TotalLines ([int]), TotalFunctions ([int]), TotalComplexity ([int]),
    AverageLinesPerFile ([double]), AverageComplexityPerFile ([double]), DuplicateFunctions ([int]).
    Type: [PSCustomObject] with numeric properties.

.EXAMPLE
    $metrics = Get-CodeMetrics -Path "scripts/utils" -Recurse
    Write-Output "Total functions: $($metrics.TotalFunctions)"
#>
function Get-CodeMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse
    )

    if (-not (Get-Command Get-PowerShellScripts -ErrorAction SilentlyContinue)) {
        throw "Get-PowerShellScripts function not available. FileSystem module may not be loaded."
    }

    $scripts = Get-PowerShellScripts -Path $Path -Recurse:$Recurse
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Host "  [code-metrics.analyze] Found $($scripts.Count) PowerShell scripts to analyze" -ForegroundColor DarkGray
    }

    # Use Collections module for better performance
    $fileMetrics = if (Get-Command New-ObjectList -ErrorAction SilentlyContinue) {
        New-ObjectList
    }
    else {
        [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    foreach ($script in $scripts) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[code-metrics.analyze] Analyzing script: $($script.FullName)"
        }
        $content = $null
        $lineCount = 0
        $functionCount = 0
        $complexity = 0
        $fileAdded = $false
        
        try {
            # Use FileContent module if available
            $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
                Read-FileContent -Path $script.FullName -ErrorAction Stop
            }
            else {
                Get-Content -Path $script.FullName -Raw -ErrorAction Stop
            }
            
            # Always count lines, even if AST parsing fails
            if ($null -ne $content) {
                $lineCount = ($content -split "`n").Count
            }
            
            # Try AST parsing, but don't fail if it doesn't work
            $ast = $null
            try {
                # Use AstParsing module for AST operations
                if (Get-Command Get-PowerShellAst -ErrorAction SilentlyContinue) {
                    try {
                        $ast = Get-PowerShellAst -Path $script.FullName
                    }
                    catch {
                        # Get-PowerShellAst failed, $ast remains null
                        $ast = $null
                    }
                    
                    if ($null -ne $ast) {
                        if (Get-Command Get-FunctionsFromAst -ErrorAction SilentlyContinue) {
                            try {
                                $functions = Get-FunctionsFromAst -Ast $ast
                                $functionCount = if ($null -ne $functions) { $functions.Count } else { 0 }
                            }
                            catch {
                                # Get-FunctionsFromAst failed, functionCount remains 0
                            }
                        }
                        if (Get-Command Get-AstComplexity -ErrorAction SilentlyContinue) {
                            try {
                                $complexity = Get-AstComplexity -Ast $ast
                            }
                            catch {
                                # Get-AstComplexity failed, complexity remains 0
                            }
                        }
                    }
                }
                else {
                    # Fallback to manual parsing if module not available
                    try {
                        $parseErrors = @()
                        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$parseErrors, [ref]$null)
                        if ($null -ne $ast -and ($null -eq $parseErrors -or $parseErrors.Count -eq 0)) {
                            $functionCount = ($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)).Count
                            $complexity = ($ast.FindAll({
                                        param($node)
                                        $node -is [System.Management.Automation.Language.IfStatementAst] -or
                                        $node -is [System.Management.Automation.Language.WhileStatementAst] -or
                                        $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
                                        $node -is [System.Management.Automation.Language.ForStatementAst] -or
                                        $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
                                        $node -is [System.Management.Automation.Language.TryStatementAst]
                                    }, $true)).Count
                        }
                    }
                    catch {
                        # Manual parsing failed, functionCount and complexity remain 0
                    }
                }
            }
            catch {
                # AST parsing failed completely, but we can still count lines
                # functionCount and complexity remain 0
            }

            # Always add file metrics, even if AST parsing failed
            if ($null -ne $script -and
                $null -ne $script.Name -and
                $null -ne $script.FullName -and
                $null -ne $fileMetrics) {
                $fileMetrics.Add([PSCustomObject]@{
                        File       = $script.Name
                        Path       = $script.FullName
                        Lines      = $lineCount
                        Functions  = $functionCount
                        Complexity = $complexity
                    })
                $fileAdded = $true
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [code-metrics.analyze] Added metrics for $($script.Name): Lines=$lineCount, Functions=$functionCount, Complexity=$complexity" -ForegroundColor DarkGray
                }
            }
        }
        catch {
            # Try to add file with minimal info even if everything failed
            if (-not $fileAdded -and
                $null -ne $script -and
                $null -ne $script.Name -and
                $null -ne $script.FullName -and
                $null -ne $fileMetrics) {
                try {
                    $fileMetrics.Add([PSCustomObject]@{
                            File       = $script.Name
                            Path       = $script.FullName
                            Lines      = $lineCount
                            Functions  = 0
                            Complexity = 0
                        })
                    $fileAdded = $true
                }
                catch {
                    # If we can't add it, just warn
                }
            }
            
            # Only warn if we can't even read the file
            $errorMsg = $_.Exception.Message
            if ($errorMsg.Length -gt 200) {
                $errorMsg = $errorMsg.Substring(0, 197) + "..."
            }
            # Also clean up repetitive patterns like multiple semicolons
            $errorMsg = $errorMsg -replace ';{3,}', ';'
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to analyze script" -OperationName 'code-metrics.analyze' -Context @{
                    script_path   = $script.FullName
                    error_message = $errorMsg
                } -Code 'ScriptAnalysisFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                Write-StructuredWarning -Message "Failed to analyze script" -OperationName 'code-metrics.analyze' -Context @{
                                    # Technical context
                                    script_path   = $script.FullName
                                    script_name   = $script.Name
                                    # Error context
                                    error_message = $errorMsg
                                    ErrorType     = $_.Exception.GetType().FullName
                                    # Operation context
                                    Recurse       = $Recurse
                                    # Invocation context
                                    FunctionName  = 'Get-CodeMetrics'
                                } -Code 'AnalysisFailed'
                            }
                            else {
                                Write-Warning "[code-metrics.analyze] Failed to analyze $($script.FullName): $errorMsg"
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Verbose "[code-metrics.analyze] Analysis failure details - ScriptPath: $($script.FullName), Exception: $($_.Exception.GetType().FullName), Message: $errorMsg, Stack: $($_.ScriptStackTrace)"
                        }
                    }
                    else {
                        # Always log warnings even if debug is off
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to analyze script" -OperationName 'code-metrics.analyze' -Context @{
                                script_path   = $script.FullName
                                script_name   = $script.Name
                                error_message = $errorMsg
                                ErrorType     = $_.Exception.GetType().FullName
                                Recurse       = $Recurse
                                FunctionName  = 'Get-CodeMetrics'
                            } -Code 'AnalysisFailed'
                        }
                        else {
                            Write-Warning "[code-metrics.analyze] Failed to analyze $($script.FullName): $errorMsg"
                        }
                    }
                }
            }
        }
    }

    # Ensure fileMetrics is initialized
    if ($null -eq $fileMetrics -or $fileMetrics.Count -eq 0) {
        $fileMetrics = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    
    $totalLines = if ($fileMetrics.Count -gt 0) { ($fileMetrics | Measure-Object -Property Lines -Sum).Sum } else { 0 }
    $totalFunctions = if ($fileMetrics.Count -gt 0) { ($fileMetrics | Measure-Object -Property Functions -Sum).Sum } else { 0 }
    $totalComplexity = if ($fileMetrics.Count -gt 0) { ($fileMetrics | Measure-Object -Property Complexity -Sum).Sum } else { 0 }
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Host "  [code-metrics.analyze] Aggregated metrics: TotalLines=$totalLines, TotalFunctions=$totalFunctions, TotalComplexity=$totalComplexity" -ForegroundColor DarkGray
    }

    # Detect code duplication (functions with identical names)
    $functionNames = if (Get-Command New-TypedList -ErrorAction SilentlyContinue) {
        New-TypedList -Type "string"
    }
    else {
        [System.Collections.Generic.List[string]]::new()
    }
    $duplicateFunctions = if (Get-Command New-ObjectList -ErrorAction SilentlyContinue) {
        New-ObjectList
    }
    else {
        [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    foreach ($fileMetric in $fileMetrics) {
        try {
            # Use AstParsing module for function discovery
            if (Get-Command Get-PowerShellAst -ErrorAction SilentlyContinue) {
                $ast = Get-PowerShellAst -Path $fileMetric.Path
                $functionAsts = Get-FunctionsFromAst -Ast $ast
            }
            else {
                # Fallback to manual parsing
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($fileMetric.Path, [ref]$null, [ref]$null)
                $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            }

            foreach ($funcAst in $functionAsts) {
                $funcName = $funcAst.Name
                if ($functionNames.Contains($funcName)) {
                    $duplicateFunctions.Add([PSCustomObject]@{
                            FunctionName = $funcName
                            File         = $fileMetric.File
                            Path         = $fileMetric.Path
                        })
                }
                else {
                    $functionNames.Add($funcName) | Out-Null
                }
            }
        }
        catch {
            # Skip files that can't be parsed
        }
    }

    # Ensure duplicateFunctions is initialized (defensive check)
    if ($null -eq $duplicateFunctions) {
        $duplicateFunctions = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    
    # Convert fileMetrics to array - this function ensures it's never null
    $fileMetricsArray = ConvertTo-FileMetricsArray -InputList $fileMetrics
    
    # Ensure fileMetricsArray is always an array, never null (defensive checks)
    if ($null -eq $fileMetricsArray) {
        $fileMetricsArray = @()
    }
    if (-not ($fileMetricsArray -is [System.Array])) {
        $fileMetricsArray = @()
    }
    
    # Create result object (without FileMetrics first)
    $result = [PSCustomObject]@{
        TotalFiles               = $scripts.Count
        TotalLines               = $totalLines
        TotalFunctions           = $totalFunctions
        TotalComplexity          = $totalComplexity
        DuplicateFunctions       = $duplicateFunctions.Count
        DuplicateFunctionDetails = $duplicateFunctions.ToArray()
        AverageLinesPerFile      = if ($scripts.Count -gt 0) { [math]::Round($totalLines / $scripts.Count, 2) } else { 0 }
        AverageFunctionsPerFile  = if ($scripts.Count -gt 0) { [math]::Round($totalFunctions / $scripts.Count, 2) } else { 0 }
        AverageComplexityPerFile = if ($scripts.Count -gt 0) { [math]::Round($totalComplexity / $scripts.Count, 2) } else { 0 }
    }
    
    # Set FileMetrics property explicitly after object creation (more reliable)
    # Use -Force to overwrite if it already exists
    $result | Add-Member -MemberType NoteProperty -Name 'FileMetrics' -Value $fileMetricsArray -Force
    
    # Final verification: ensure FileMetrics is never null (defensive check)
    # Double-check that the property was set correctly
    if ($null -eq $result.FileMetrics) {
        # Last resort: remove and re-add the property
        $emptyArray = @()
        if ($result.PSObject.Properties['FileMetrics']) {
            $result.PSObject.Properties.Remove('FileMetrics')
        }
        $result | Add-Member -MemberType NoteProperty -Name 'FileMetrics' -Value $emptyArray -Force
    }
    
    # One more safety check - verify the property exists and is not null
    if (-not $result.PSObject.Properties['FileMetrics'] -or $null -eq $result.PSObject.Properties['FileMetrics'].Value) {
        $emptyArray = @()
        $result | Add-Member -MemberType NoteProperty -Name 'FileMetrics' -Value $emptyArray -Force
    }
    
    return $result
}

Export-ModuleMember -Function @(
    'Get-CodeMetrics',
    'ConvertTo-FileMetricsArray'
)

