<#
scripts/utils/code-quality/validate-function-naming.ps1

.SYNOPSIS
    Validates PowerShell function naming conventions across the codebase.

.DESCRIPTION
    Audits all functions in the codebase to ensure they follow PowerShell naming conventions:
    - Functions follow Verb-Noun pattern
    - Verbs are from approved PowerShell verbs (Get-Verb)
    - Profile functions use Set-AgentModeFunction for collision-safe registration
    - Documents exceptions to naming conventions

.PARAMETER Path
    Path to analyze. Defaults to repository root.

.PARAMETER OutputPath
    Optional path to save validation report JSON file.

.PARAMETER ExceptionsFile
    Optional path to exceptions documentation file. Defaults to docs/FUNCTION_NAMING_EXCEPTIONS.md

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1

    Validates all functions in the codebase.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1 -Path profile.d

    Validates functions in profile.d directory only.

.OUTPUTS
    PSCustomObject with validation results including:
    - Total functions found
    - Functions with approved verbs
    - Functions with unapproved verbs
    - Functions not using Set-AgentModeFunction in profile.d
    - Exceptions documented
#>

[CmdletBinding()]
param(
    [string]$Path = $null,
    
    [string]$OutputPath = $null,
    
    [string]$ExceptionsFile = $null
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'Common.psm1'
if (Test-Path $commonModulePath) {
    Import-Module $commonModulePath -ErrorAction Stop
}

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    # Fallback if Get-RepoRoot not available
    $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

# Set default paths
if (-not $Path) {
    $Path = $repoRoot
}

if (-not $ExceptionsFile) {
    $ExceptionsFile = Join-Path $repoRoot 'docs' 'FUNCTION_NAMING_EXCEPTIONS.md'
}

# Get approved PowerShell verbs
$approvedVerbs = (Get-Verb).Verb | Sort-Object

# Function to check if a verb is approved
function Test-ApprovedVerb {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Verb
    )
    return $Verb -in $approvedVerbs
}

# Function to extract verb and noun from function name
function Get-FunctionParts {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName
    )
    
    if ($FunctionName -match '^([A-Za-z]+)-([A-Za-z0-9_]+)$') {
        return @{
            Verb          = $matches[1]
            Noun          = $matches[2]
            IsValidFormat = $true
        }
    }
    else {
        return @{
            Verb          = $null
            Noun          = $null
            IsValidFormat = $false
        }
    }
}

# Function to check if function uses Set-AgentModeFunction
function Test-UsesAgentModeFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string]$FunctionName
    )
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    $content = Get-Content -Path $FilePath -Raw
    $functionPattern = [regex]::Escape($FunctionName)
    
    # Check if function is defined using Set-AgentModeFunction
    if ($content -match "Set-AgentModeFunction\s+-Name\s+['`"]$functionPattern['`"]") {
        return $true
    }
    
    # Check if function is defined using lazy loading pattern
    if ($content -match "Register-LazyFunction\s+-Name\s+['`"]$functionPattern['`"]") {
        return $true
    }
    
    # Check if function is a lazy-loading stub (checks for function existence and calls Ensure-*)
    if ($content -match "function\s+$functionPattern\s*\{[^}]*Ensure-[A-Za-z]+") {
        return $true  # Lazy-loading stub is a valid pattern
    }
    
    # Check if function is defined using direct function keyword
    if ($content -match "(?m)^\s*function\s+$functionPattern\s*\{") {
        return $false
    }
    
    return $null  # Unknown pattern
}

# Function to check if function is a bootstrap function (exception)
function Test-IsBootstrapFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string]$FunctionName
    )
    
    # Bootstrap functions are in 00-bootstrap.ps1
    if ($FilePath -like '*\00-bootstrap.ps1' -or $FilePath -like '*/00-bootstrap.ps1') {
        $bootstrapFunctions = @(
            'Set-AgentModeFunction',
            'Set-AgentModeAlias',
            'Test-CachedCommand',
            'Test-HasCommand',
            'Test-IsWindows',
            'Test-IsLinux',
            'Test-IsMacOS',
            'Get-UserHome',
            'Register-LazyFunction',
            'Register-DeprecatedFunction',
            'Get-FragmentConfigPath',
            'Get-FragmentConfig',
            'ConvertTo-Hashtable',
            'Save-FragmentConfig',
            'Test-ProfileFragmentEnabled',
            'Enable-ProfileFragment',
            'Disable-ProfileFragment',
            'Get-ProfileFragment',
            'Get-FragmentDependencies',
            'Test-FragmentDependencies',
            'Get-FragmentLoadOrder',
            'Visit-Fragment'
        )
        return $FunctionName -in $bootstrapFunctions
    }
    
    return $false
}

# Collect all functions
$functions = @()
$profileDFiles = @()
$scriptFiles = @()

# Find all PowerShell files
$psFiles = Get-ChildItem -Path $Path -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue |
Where-Object { $_.FullName -notlike '*\node_modules\*' -and $_.FullName -notlike '*\.git\*' }

foreach ($file in $psFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    # Track profile.d files separately
    if ($file.FullName -like '*\profile.d\*') {
        $profileDFiles += $file
    }
    else {
        $scriptFiles += $file
    }
    
    # Find function definitions
    # Match: function Verb-Noun { or function Verb-Noun(
    $functionMatches = [regex]::Matches($content, '(?m)^\s*function\s+([A-Za-z]+-[A-Za-z0-9_]+)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    foreach ($match in $functionMatches) {
        $functionName = $match.Groups[1].Value
        $parts = Get-FunctionParts -FunctionName $functionName
        
        $usesAgentMode = Test-UsesAgentModeFunction -FilePath $file.FullName -FunctionName $functionName
        
        $functions += [PSCustomObject]@{
            Name                     = $functionName
            Verb                     = $parts.Verb
            Noun                     = $parts.Noun
            IsValidFormat            = $parts.IsValidFormat
            HasApprovedVerb          = if ($parts.Verb) { Test-ApprovedVerb -Verb $parts.Verb } else { $false }
            FilePath                 = $file.FullName
            RelativePath             = $file.FullName.Replace($repoRoot, '').TrimStart('\', '/')
            IsProfileDFile           = $file.FullName -like '*\profile.d\*'
            UsesSetAgentModeFunction = $usesAgentMode
        }
    }
    
    # Also find functions created via Set-AgentModeFunction
    $agentModeMatches = [regex]::Matches($content, "Set-AgentModeFunction\s+-Name\s+['`"]([A-Za-z]+-[A-Za-z0-9_]+)['`"]", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $agentModeMatches) {
        $functionName = $match.Groups[1].Value
        $parts = Get-FunctionParts -FunctionName $functionName
        
        # Check if we already found this function
        if ($functions | Where-Object { $_.Name -eq $functionName -and $_.FilePath -eq $file.FullName }) {
            continue
        }
        
        $functions += [PSCustomObject]@{
            Name                     = $functionName
            Verb                     = $parts.Verb
            Noun                     = $parts.Noun
            IsValidFormat            = $parts.IsValidFormat
            HasApprovedVerb          = if ($parts.Verb) { Test-ApprovedVerb -Verb $parts.Verb } else { $false }
            FilePath                 = $file.FullName
            RelativePath             = $file.FullName.Replace($repoRoot, '').TrimStart('\', '/')
            IsProfileDFile           = $file.FullName -like '*\profile.d\*'
            UsesSetAgentModeFunction = $true
        }
    }
}

# Load exceptions if file exists
$exceptions = @{}
$exceptionVerbs = @('Ensure', 'Reload', 'Continue', 'Jump', 'Time', 'am', 'Simple', 'Visit')
if (Test-Path $ExceptionsFile) {
    $exceptionContent = Get-Content -Path $ExceptionsFile -Raw
    # Parse function names from exceptions list
    $exceptionMatches = [regex]::Matches($exceptionContent, '(?:^|\n)\s*-\s+`?([A-Za-z]+-[A-Za-z0-9_]+)`?')
    foreach ($match in $exceptionMatches) {
        $exceptions[$match.Groups[1].Value] = $true
    }
    
    # Also extract exception verbs mentioned in documentation
    if ($exceptionContent -match 'Exception Categories') {
        # Extract verbs from "Common Utility Patterns" section
        if ($exceptionContent -match 'Reload|Continue|Jump|Time') {
            # Already in exceptionVerbs
        }
    }
}

# Function to check if exception applies
function Test-IsException {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,
        
        [Parameter(Mandatory)]
        [string]$Verb,
        
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    # Check if function is in exceptions list
    if ($exceptions.ContainsKey($FunctionName)) {
        return $true
    }
    
    # Check if verb is in exception verbs list
    if ($Verb -in $exceptionVerbs) {
        return $true
    }
    
    # Check if it's a bootstrap function
    if (Test-IsBootstrapFunction -FilePath $FilePath -FunctionName $FunctionName) {
        return $true
    }
    
    # Check if it's a test file
    if ($FilePath -like '*\tests\*' -or $FilePath -like '*/tests/*') {
        return $true
    }
    
    return $false
}

# Analyze results
$results = [PSCustomObject]@{
    TotalFunctions                     = $functions.Count
    FunctionsWithApprovedVerbs         = ($functions | Where-Object { $_.HasApprovedVerb }).Count
    FunctionsWithUnapprovedVerbs       = ($functions | Where-Object { 
            $_.IsValidFormat -and -not $_.HasApprovedVerb -and -not (Test-IsException -FunctionName $_.Name -Verb $_.Verb -FilePath $_.FilePath)
        }).Count
    FunctionsWithInvalidFormat         = ($functions | Where-Object { -not $_.IsValidFormat }).Count
    ProfileDFunctionsNotUsingAgentMode = ($functions | Where-Object { 
            $_.IsProfileDFile -and -not $_.UsesSetAgentModeFunction -and -not (Test-IsException -FunctionName $_.Name -Verb $_.Verb -FilePath $_.FilePath)
        }).Count
    ExceptionsCount                    = $exceptions.Count
    Functions                          = $functions
    Issues                             = @()
}

# Identify issues
foreach ($func in $functions) {
    # Skip exceptions
    if (Test-IsException -FunctionName $func.Name -Verb $func.Verb -FilePath $func.FilePath) {
        continue
    }
    
    $issues = @()
    
    if (-not $func.IsValidFormat) {
        $issues += "Invalid format (not Verb-Noun)"
    }
    
    if ($func.IsValidFormat -and -not $func.HasApprovedVerb) {
        $issues += "Unapproved verb: $($func.Verb)"
    }
    
    if ($func.IsProfileDFile -and -not $func.UsesSetAgentModeFunction) {
        $issues += "Profile function not using Set-AgentModeFunction"
    }
    
    if ($issues.Count -gt 0) {
        $results.Issues += [PSCustomObject]@{
            FunctionName             = $func.Name
            FilePath                 = $func.RelativePath
            Issues                   = $issues -join '; '
            Verb                     = $func.Verb
            HasApprovedVerb          = $func.HasApprovedVerb
            UsesSetAgentModeFunction = $func.UsesSetAgentModeFunction
        }
    }
}

# Display results
Write-Host "`nFunction Naming Validation Results" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Total Functions Found: $($results.TotalFunctions)" -ForegroundColor White
Write-Host "Functions with Approved Verbs: $($results.FunctionsWithApprovedVerbs)" -ForegroundColor Green
Write-Host "Functions with Unapproved Verbs: $($results.FunctionsWithUnapprovedVerbs)" -ForegroundColor $(if ($results.FunctionsWithUnapprovedVerbs -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Functions with Invalid Format: $($results.FunctionsWithInvalidFormat)" -ForegroundColor $(if ($results.FunctionsWithInvalidFormat -eq 0) { 'Green' } else { 'Red' })
Write-Host "Profile.d Functions Not Using Set-AgentModeFunction: $($results.ProfileDFunctionsNotUsingAgentMode)" -ForegroundColor $(if ($results.ProfileDFunctionsNotUsingAgentMode -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Documented Exceptions: $($results.ExceptionsCount)" -ForegroundColor White

if ($results.Issues.Count -gt 0) {
    Write-Host "`nIssues Found:" -ForegroundColor Yellow
    foreach ($issue in $results.Issues) {
        Write-Host "  - $($issue.FunctionName) ($($issue.FilePath)): $($issue.Issues)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "`n✓ No issues found!" -ForegroundColor Green
}

# Save report if requested
if ($OutputPath) {
    $report = @{
        Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Summary      = @{
            TotalFunctions                     = $results.TotalFunctions
            FunctionsWithApprovedVerbs         = $results.FunctionsWithApprovedVerbs
            FunctionsWithUnapprovedVerbs       = $results.FunctionsWithUnapprovedVerbs
            FunctionsWithInvalidFormat         = $results.FunctionsWithInvalidFormat
            ProfileDFunctionsNotUsingAgentMode = $results.ProfileDFunctionsNotUsingAgentMode
            ExceptionsCount                    = $results.ExceptionsCount
        }
        Issues       = $results.Issues | ForEach-Object {
            @{
                FunctionName             = $_.FunctionName
                FilePath                 = $_.FilePath
                Issues                   = $_.Issues
                Verb                     = $_.Verb
                HasApprovedVerb          = $_.HasApprovedVerb
                UsesSetAgentModeFunction = $_.UsesSetAgentModeFunction
            }
        }
        AllFunctions = $results.Functions | ForEach-Object {
            @{
                Name                     = $_.Name
                Verb                     = $_.Verb
                Noun                     = $_.Noun
                HasApprovedVerb          = $_.HasApprovedVerb
                FilePath                 = $_.RelativePath
                IsProfileDFile           = $_.IsProfileDFile
                UsesSetAgentModeFunction = $_.UsesSetAgentModeFunction
            }
        }
    }
    
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    Write-Host "`nReport saved to: $OutputPath" -ForegroundColor Green
}

# Return exit code based on issues
if ($results.Issues.Count -gt 0) {
    exit 1
}
else {
    exit 0
}

