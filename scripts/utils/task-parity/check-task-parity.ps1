<#
.SYNOPSIS
    Checks task parity across all task runner files (Taskfile.yml, Makefile, package.json, justfile, .vscode/tasks.json).

.DESCRIPTION
    Analyzes task definitions across all task runner files and reports:
    - Tasks present in one file but missing in others
    - Command differences for the same task name
    - Summary statistics
    
    Optionally can generate missing tasks to achieve parity.

.PARAMETER Generate
    If specified, generates missing tasks in target files to achieve parity.
    Default: $false (only reports differences)

.PARAMETER TargetFile
    When generating, specify which file(s) to update. Options: 'all', 'taskfile', 'makefile', 'package', 'justfile', 'tasksjson'.
    Default: 'all'

.PARAMETER RepoRoot
    Repository root directory. Auto-detected if not specified.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\task-parity\check-task-parity.ps1
    
    Reports task parity differences without making changes.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\task-parity\check-task-parity.ps1 -Generate -TargetFile 'makefile'
    
    Generates missing tasks in Makefile only.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\task-parity\check-task-parity.ps1 -Generate
    
    Generates missing tasks in all files to achieve full parity.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Generate,
    
    [ValidateSet('all', 'taskfile', 'makefile', 'package', 'justfile', 'tasksjson')]
    [string]$TargetFile = 'all',
    
    [string]$RepoRoot = $null
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Host "  [task-parity] Starting task parity check" -ForegroundColor DarkGray
}

# Resilience Features:
# - PathResolution import failure: Falls back to manual repo root detection
# - ModuleImport import failure: Falls back to direct module imports
# - ExitCodes import failure: Falls back to numeric exit codes
# - Optional modules (Logging, JsonUtilities): Script continues without them
# - File parsing: Retry logic with exponential backoff
# - Task generation: Creates backups, validates file writability
# - Comparison: Validates data structures before processing
# - Error handling: All critical operations wrapped in try-catch with fallbacks

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and -not [string]::IsNullOrWhiteSpace($pathResolutionPath) -and -not (Test-Path -LiteralPath $pathResolutionPath)) {
    $errorMsg = "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileNotFoundException]::new($errorMsg),
            'PathResolutionNotFound',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $pathResolutionPath
        )) -OperationName "task-parity.setup" -Context @{
            script_path = $PSScriptRoot
            expected_path = $pathResolutionPath
        }
    }
    else {
        Write-Error $errorMsg
    }
    exit 1
}

$pathResolutionImported = $false
try {
    Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop
    $pathResolutionImported = $true
    if ($debugLevel -ge 2) {
        Write-Host "  [task-parity] PathResolution module imported successfully" -ForegroundColor DarkGray
    }
}
catch {
    $errorDetails = $_.Exception.Message
    if ($debugLevel -ge 1) {
        Write-Host "  [task-parity] PathResolution import failed, using fallback: $errorDetails" -ForegroundColor Yellow
    }
    # Continue without PathResolution - we'll use manual repo root resolution
    $pathResolutionImported = $false
}

# Import ModuleImport (bootstrap) with resilience
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
$moduleImportImported = $false

if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
    $errorMsg = "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileNotFoundException]::new($errorMsg),
            'ModuleImportNotFound',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $moduleImportPath
        )) -OperationName "task-parity.setup" -Context @{
            script_path = $PSScriptRoot
            expected_path = $moduleImportPath
        }
    }
    else {
        Write-Error $errorMsg
    }
    exit 1
}

try {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
    $moduleImportImported = $true
    if ($debugLevel -ge 2) {
        Write-Host "  [task-parity] ModuleImport module imported successfully" -ForegroundColor DarkGray
    }
}
catch {
    $errorDetails = $_.Exception.Message
    if ($debugLevel -ge 1) {
        Write-Host "  [task-parity] ModuleImport import failed, will use direct module imports: $errorDetails" -ForegroundColor Yellow
    }
    # Continue without ModuleImport - we'll import modules directly
    $moduleImportImported = $false
}

# Import shared utilities with resilience (direct imports if ModuleImport failed)
# Track which modules were successfully imported
$importedModules = @{
    ExitCodes = $false
    Logging = $false
    JsonUtilities = $false
}

# Import ExitCodes directly first (needed for Exit-WithCode)
$exitCodesPath = Join-Path $scriptsDir 'lib' 'core' 'ExitCodes.psm1'
if (Test-Path -LiteralPath $exitCodesPath) {
    try {
        Import-Module $exitCodesPath -DisableNameChecking -ErrorAction Stop -Global
        $importedModules.ExitCodes = $true
        if ($debugLevel -ge 2) {
            Write-Host "  [task-parity] ExitCodes imported directly" -ForegroundColor DarkGray
        }
    }
    catch {
        if ($debugLevel -ge 1) {
            Write-Host "  [task-parity] ExitCodes direct import failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        # Try via Import-LibModule if available
        if ($moduleImportImported -and (Get-Command Import-LibModule -ErrorAction SilentlyContinue)) {
            try {
                Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
                if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                    $importedModules.ExitCodes = $true
                    if ($debugLevel -ge 2) {
                        Write-Host "  [task-parity] ExitCodes imported via Import-LibModule" -ForegroundColor DarkGray
                    }
                }
            }
            catch {
                if ($debugLevel -ge 1) {
                    Write-Host "  [task-parity] ExitCodes import failed, will use fallback exit codes" -ForegroundColor Yellow
                }
            }
        }
    }
}
else {
    # Try via Import-LibModule if available
    if ($moduleImportImported -and (Get-Command Import-LibModule -ErrorAction SilentlyContinue)) {
        try {
            Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
            if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                $importedModules.ExitCodes = $true
            }
        }
        catch {
            if ($debugLevel -ge 1) {
                Write-Host "  [task-parity] ExitCodes not available, will use fallback exit codes" -ForegroundColor Yellow
            }
        }
    }
}

# Import Logging (optional, script can work without it)
if ($moduleImportImported -and (Get-Command Import-LibModule -ErrorAction SilentlyContinue)) {
    try {
        Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
        $importedModules.Logging = $true
    }
    catch {
        if ($debugLevel -ge 2) {
            Write-Host "  [task-parity] Logging module not available, continuing without it" -ForegroundColor DarkGray
        }
    }
}

# Import JsonUtilities (optional, only needed for package.json parsing which has fallback)
if ($moduleImportImported -and (Get-Command Import-LibModule -ErrorAction SilentlyContinue)) {
    try {
        Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
        $importedModules.JsonUtilities = $true
    }
    catch {
        if ($debugLevel -ge 2) {
            Write-Host "  [task-parity] JsonUtilities module not available, will use native ConvertFrom-Json" -ForegroundColor DarkGray
        }
    }
}

# Resolve repository root
if (-not $RepoRoot) {
    try {
        if ($pathResolutionImported -and (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue)) {
            $RepoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
            if ($debugLevel -ge 2) {
                Write-Host "  [task-parity] Resolved repository root via Get-RepoRoot: $RepoRoot" -ForegroundColor DarkGray
            }
        }
        else {
            # Fallback: manually calculate repo root by going up from scripts/utils/task-parity
            # scripts/utils/task-parity -> scripts/utils -> scripts -> repo root (3 levels up)
            $currentPath = $PSScriptRoot
            $repoRoot = $null
            $maxDepth = 10  # Increased to handle deeper directory structures
            $depth = 0
            
            if ($debugLevel -ge 1) {
                Write-Host "  [task-parity] Starting repository root detection from: $currentPath" -ForegroundColor DarkGray
            }
            
            # Normalize the path first
            if (-not [string]::IsNullOrWhiteSpace($currentPath)) {
                try {
                    $currentPath = [System.IO.Path]::GetFullPath($currentPath)
                    if ($debugLevel -ge 2) {
                        Write-Host "  [task-parity] Normalized path: $currentPath" -ForegroundColor DarkGray
                    }
                }
                catch {
                    # If path normalization fails, use as-is
                    if ($debugLevel -ge 1) {
                        Write-Host "  [task-parity] Path normalization failed, using original path: $currentPath" -ForegroundColor Yellow
                    }
                }
            }
            
            # Ensure we have a valid starting path
            if ([string]::IsNullOrWhiteSpace($currentPath)) {
                throw "Starting path is null or empty. PSScriptRoot: $PSScriptRoot"
            }
            
            if (-not (Test-Path -LiteralPath $currentPath -PathType Container)) {
                throw "Starting path does not exist or is not a directory: $currentPath (PSScriptRoot: $PSScriptRoot)"
            }
            
            # Always check at least the starting directory and go up from there
            while ($null -eq $repoRoot -and $depth -lt $maxDepth -and -not [string]::IsNullOrWhiteSpace($currentPath)) {
                # Check if we're at the repo root (has .git, Taskfile.yml, Makefile, etc.)
                $gitPath = Join-Path $currentPath '.git'
                $taskfilePath = Join-Path $currentPath 'Taskfile.yml'
                $makefilePath = Join-Path $currentPath 'Makefile'
                
                if ($debugLevel -ge 2) {
                    Write-Host "  [task-parity] Checking level $depth : $currentPath" -ForegroundColor DarkGray
                    Write-Host "    .git exists: $(Test-Path -LiteralPath $gitPath)" -ForegroundColor DarkGray
                    Write-Host "    Taskfile.yml exists: $(Test-Path -LiteralPath $taskfilePath)" -ForegroundColor DarkGray
                    Write-Host "    Makefile exists: $(Test-Path -LiteralPath $makefilePath)" -ForegroundColor DarkGray
                }
                
                $hasGit = Test-Path -LiteralPath $gitPath
                $hasTaskfile = Test-Path -LiteralPath $taskfilePath
                $hasMakefile = Test-Path -LiteralPath $makefilePath
                
                if ($hasGit -or ($hasTaskfile -and $hasMakefile)) {
                    $repoRoot = $currentPath
                    if ($debugLevel -ge 1) {
                        Write-Host "  [task-parity] Found repository root at level $depth : $repoRoot" -ForegroundColor Green
                    }
                    break
                }
                
                # Move up one level before next iteration
                try {
                    $parent = Split-Path -Parent $currentPath -ErrorAction Stop
                    
                    # Check if we've reached the filesystem root
                    if ([string]::IsNullOrWhiteSpace($parent)) {
                        if ($debugLevel -ge 2) {
                            Write-Host "  [task-parity] Reached filesystem root (parent is null) at level $depth" -ForegroundColor DarkGray
                        }
                        break
                    }
                    
                    # Normalize parent path for comparison
                    $normalizedParent = [System.IO.Path]::GetFullPath($parent)
                    $normalizedCurrent = [System.IO.Path]::GetFullPath($currentPath)
                    
                    if ($normalizedParent -eq $normalizedCurrent) {
                        if ($debugLevel -ge 2) {
                            Write-Host "  [task-parity] Reached filesystem root (parent equals current) at level $depth" -ForegroundColor DarkGray
                        }
                        break
                    }
                    
                    # Increment depth and move to parent for next iteration
                    $depth++
                    $currentPath = $normalizedParent
                    
                    if ($debugLevel -ge 2) {
                        Write-Host "  [task-parity] Moving up to level $depth : $currentPath" -ForegroundColor DarkGray
                    }
                }
                catch {
                    if ($debugLevel -ge 1) {
                        Write-Host "  [task-parity] Failed to get parent path at level $depth : $_" -ForegroundColor Yellow
                    }
                    break
                }
            }
            
            if ($repoRoot) {
                $RepoRoot = $repoRoot
                if ($debugLevel -ge 1) {
                    Write-Host "  [task-parity] Resolved repository root via fallback: $RepoRoot" -ForegroundColor Green
                }
            }
            else {
                # Last resort: Try relative path from script location
                # Script is at scripts/utils/task-parity/check-task-parity.ps1
                # Repo root should be 3 levels up
                $relativeRepoRoot = Join-Path $PSScriptRoot '..\..\..' | Resolve-Path -ErrorAction SilentlyContinue
                if ($relativeRepoRoot) {
                    $relativeRepoRoot = $relativeRepoRoot.Path
                    $gitPath = Join-Path $relativeRepoRoot '.git'
                    $taskfilePath = Join-Path $relativeRepoRoot 'Taskfile.yml'
                    $makefilePath = Join-Path $relativeRepoRoot 'Makefile'
                    
                    if ((Test-Path -LiteralPath $gitPath) -or 
                        ((Test-Path -LiteralPath $taskfilePath) -and (Test-Path -LiteralPath $makefilePath))) {
                        $RepoRoot = $relativeRepoRoot
                        if ($debugLevel -ge 1) {
                            Write-Host "  [task-parity] Resolved repository root via relative path fallback: $RepoRoot" -ForegroundColor Green
                        }
                    }
                }
                
                if (-not $RepoRoot) {
                    # Provide detailed error information
                    $errorDetails = @(
                        "Could not determine repository root."
                        "Searched up $depth levels from: $PSScriptRoot"
                        "Last checked path: $currentPath"
                        "Max depth: $maxDepth"
                        "Relative path fallback also failed."
                    ) -join " "
                    
                    if ($debugLevel -ge 1) {
                        Write-Host "  [task-parity] Repository root detection failed:" -ForegroundColor Yellow
                        Write-Host "    Starting path: $PSScriptRoot" -ForegroundColor Yellow
                        Write-Host "    Levels searched: $depth" -ForegroundColor Yellow
                        Write-Host "    Last checked: $currentPath" -ForegroundColor Yellow
                        Write-Host "    Relative fallback tried: $relativeRepoRoot" -ForegroundColor Yellow
                    }
                    
                    throw $errorDetails
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "task-parity.setup" -Context @{
                script_path = $PSScriptRoot
                path_resolution_imported = $pathResolutionImported
            }
        }
        else {
            Write-Error "Failed to resolve repository root: $_"
        }
        # Use Exit-WithCode if available, otherwise use numeric exit code
        if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
            try {
                Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
            }
            catch {
                exit 2
            }
        }
        else {
            exit 2
        }
    }
}

Write-Host "`nTask Parity Checker" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

# Import task parser modules with resilience
$modulesPath = Join-Path $PSScriptRoot 'modules'
$parserModules = @{
    TaskParser = $false
    TaskComparator = $false
    TaskGenerator = $false
}

# Determine required vs optional modules based on -Generate flag
$requiredModules = @('TaskParser.psm1', 'TaskComparator.psm1')
$optionalModules = @()

# TaskGenerator is required if -Generate is used, otherwise optional
if ($Generate) {
    $requiredModules += 'TaskGenerator.psm1'
}
else {
    $optionalModules += 'TaskGenerator.psm1'
}

foreach ($moduleFile in ($requiredModules + $optionalModules)) {
    $moduleName = $moduleFile -replace '\.psm1$', ''
    $modulePath = Join-Path $modulesPath $moduleFile
    
    if (-not (Test-Path -LiteralPath $modulePath)) {
        if ($moduleFile -in $requiredModules) {
            $errorMsg = "Required module not found: $modulePath"
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                    [System.IO.FileNotFoundException]::new($errorMsg),
                    'ModuleNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $modulePath
                )) -OperationName "task-parity.setup" -Context @{
                    module_name = $moduleName
                    module_path = $modulePath
                }
            }
            else {
                Write-Error $errorMsg
            }
            if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
                try {
                    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Required module not found: $moduleName"
                }
                catch {
                    exit 2
                }
            }
            else {
                exit 2
            }
        }
        else {
            if ($debugLevel -ge 1) {
                Write-Host "  [task-parity] Optional module not found: $moduleName (will be needed if -Generate is used)" -ForegroundColor Yellow
            }
        }
        continue
    }
    
    try {
        Import-Module $modulePath -DisableNameChecking -ErrorAction Stop
        $parserModules[$moduleName] = $true
        if ($debugLevel -ge 1) {
            Write-Host "  [task-parity] Loaded module: $moduleName" -ForegroundColor Green
        }
        if ($debugLevel -ge 2) {
            # Verify exported functions are available
            $exportedFunctions = Get-Module $moduleName | Select-Object -ExpandProperty ExportedFunctions -ErrorAction SilentlyContinue
            if ($exportedFunctions) {
                Write-Host "  [task-parity] Module $moduleName exports: $($exportedFunctions.Keys -join ', ')" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        if ($moduleFile -in $requiredModules) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "task-parity.setup" -Context @{
                    module_name = $moduleName
                    module_path = $modulePath
                }
            }
            else {
                Write-Error "Failed to import required module $moduleName : $_"
            }
            if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
                try {
                    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
                }
                catch {
                    exit 2
                }
            }
            else {
                exit 2
            }
        }
        else {
            # Optional module failed - log warning
            if ($debugLevel -ge 1) {
                Write-Host "  [task-parity] Failed to import optional module $moduleName : $_" -ForegroundColor Yellow
            }
            # If this is TaskGenerator and -Generate is used, it should have been in requiredModules
            # But if it somehow got here, we need to handle it
            if ($moduleName -eq 'TaskGenerator' -and $Generate) {
                $errorMsg = "TaskGenerator module failed to import but is required for -Generate: $_"
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName "task-parity.setup" -Context @{
                        module_name = $moduleName
                        module_path = $modulePath
                        generate_requested = $true
                    }
                }
                else {
                    Write-Error $errorMsg
                }
                if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
                    try {
                        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message $errorMsg
                    }
                    catch {
                        exit 2
                    }
                }
                else {
                    exit 2
                }
            }
        }
    }
}

if ($debugLevel -ge 2) {
    $loadedModules = $parserModules.Keys | Where-Object { $parserModules[$_] }
    if ($loadedModules) {
        Write-Host "  [task-parity] Task parser modules loaded: $($loadedModules -join ', ')" -ForegroundColor DarkGray
    }
}

# Verify TaskGenerator is available if -Generate is used
if ($Generate) {
    $taskGeneratorPath = Join-Path $modulesPath 'TaskGenerator.psm1'
    $taskGeneratorAvailable = $parserModules.TaskGenerator
    
    # Also check if the function is actually available
    $functionAvailable = $false
    if ($taskGeneratorAvailable) {
        $functionAvailable = (Get-Command Add-MissingTasks -ErrorAction SilentlyContinue) -ne $null
    }
    
    if (-not $taskGeneratorAvailable -or -not $functionAvailable) {
        $errorDetails = @()
        if (-not (Test-Path -LiteralPath $taskGeneratorPath)) {
            $errorDetails += "Module file not found: $taskGeneratorPath"
        }
        elseif (-not $taskGeneratorAvailable) {
            $errorDetails += "Module failed to import (check syntax errors)"
        }
        elseif (-not $functionAvailable) {
            $errorDetails += "Module imported but Add-MissingTasks function not available"
        }
        
        $errorMsg = "TaskGenerator module is required for -Generate but is not available. $($errorDetails -join '. ')"
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                [System.Management.Automation.ItemNotFoundException]::new($errorMsg),
                'TaskGeneratorNotLoaded',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'TaskGenerator'
            )) -OperationName "task-parity.setup" -Context @{
                generate_requested = $true
                module_path = $taskGeneratorPath
                module_file_exists = (Test-Path -LiteralPath $taskGeneratorPath)
                module_imported = $taskGeneratorAvailable
                function_available = $functionAvailable
            }
        }
        else {
            Write-Error $errorMsg
        }
        if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
            try {
                Exit-WithCode -ExitCode [ExitCode]::SetupError -Message $errorMsg
            }
            catch {
                exit 2
            }
        }
        else {
            exit 2
        }
    }
}

# Define task file paths with validation
$taskFiles = @{
    'taskfile' = Join-Path $RepoRoot 'Taskfile.yml'
    'makefile' = Join-Path $RepoRoot 'Makefile'
    'package' = Join-Path $RepoRoot 'package.json'
    'justfile' = Join-Path $RepoRoot 'justfile'
    'tasksjson' = Join-Path $RepoRoot '.vscode' 'tasks.json'
}

# Validate repo root is accessible
if (-not (Test-Path -LiteralPath $RepoRoot)) {
    $errorMsg = "Repository root path does not exist: $RepoRoot"
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
            [System.IO.DirectoryNotFoundException]::new($errorMsg),
            'RepoRootNotFound',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $RepoRoot
        )) -OperationName "task-parity.setup" -Context @{
            repo_root = $RepoRoot
            script_path = $PSScriptRoot
        }
    }
    else {
        Write-Error $errorMsg
    }
    if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
        try {
            Exit-WithCode -ExitCode [ExitCode]::SetupError -Message $errorMsg
        }
        catch {
            exit 2
        }
    }
    else {
        exit 2
    }
}

# Parse tasks from all files
Write-Host "Parsing task files..." -ForegroundColor Yellow
$allTasks = @{}

foreach ($fileType in $taskFiles.Keys) {
    $filePath = $taskFiles[$fileType]
    
    if (-not (Test-Path -LiteralPath $filePath)) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Task file not found" -OperationName "task-parity.parse" -Context @{
                file_type = $fileType
                file_path = $filePath
            } -Code "FILE_NOT_FOUND"
        }
        else {
            Write-Warning "Task file not found: $filePath"
        }
        # Initialize empty task set for this file type to maintain structure
        $allTasks[$fileType] = @{}
        continue
    }
    
    # Retry logic for parsing (sometimes file locks or transient errors occur)
    $maxRetries = 2
    $retryCount = 0
    $parsed = $false
    
    while (-not $parsed -and $retryCount -le $maxRetries) {
        try {
            if ($debugLevel -ge 2) {
                if ($retryCount -gt 0) {
                    Write-Host "  [task-parity] Retry $retryCount/$maxRetries parsing $fileType..." -ForegroundColor DarkGray
                }
                else {
                    Write-Host "  [task-parity] Parsing $fileType..." -ForegroundColor DarkGray
                }
            }
            
            # Verify file is readable before parsing
            $fileInfo = Get-Item -LiteralPath $filePath -ErrorAction Stop
            if ($fileInfo.Length -eq 0) {
                throw "File is empty: $filePath"
            }
            
            $tasks = Get-TasksFromFile -FilePath $filePath -FileType $fileType
            
            # Validate parsed tasks
            if ($null -eq $tasks) {
                throw "Parser returned null for $fileType"
            }
            
            $allTasks[$fileType] = $tasks
            $fileDisplayName = switch ($fileType) {
                'taskfile' { 'Taskfile.yml' }
                'makefile' { 'Makefile' }
                'package' { 'package.json' }
                'justfile' { 'justfile' }
                'tasksjson' { '.vscode/tasks.json' }
                default { $fileType }
            }
            Write-Host "    $fileDisplayName : Found $($tasks.Count) tasks" -ForegroundColor Green
            if ($debugLevel -ge 3) {
                Write-Host "  [task-parity] Parsed ${fileType}: $($tasks.Count) tasks" -ForegroundColor DarkGray
            }
            $parsed = $true
        }
        catch {
            $retryCount++
            if ($retryCount -gt $maxRetries) {
                # Final failure after retries
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to parse task file after $maxRetries retries" -OperationName "task-parity.parse" -Context @{
                        file_type = $fileType
                        file_path = $filePath
                        error = $_.Exception.Message
                        retry_count = $retryCount
                    } -Code "PARSE_ERROR"
                }
                else {
                    Write-Warning "Failed to parse $fileType after $maxRetries retries: $_"
                }
                if ($debugLevel -ge 2) {
                    Write-Host "  [task-parity] Parse error details: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
                }
                # Initialize empty task set to allow comparison to continue
                $allTasks[$fileType] = @{}
                $fileDisplayName = switch ($fileType) {
                    'taskfile' { 'Taskfile.yml' }
                    'makefile' { 'Makefile' }
                    'package' { 'package.json' }
                    'justfile' { 'justfile' }
                    'tasksjson' { '.vscode/tasks.json' }
                    default { $fileType }
                }
                Write-Host "    $fileDisplayName : 0 tasks (parse failed)" -ForegroundColor Yellow
            }
            else {
                # Wait briefly before retry (exponential backoff)
                if ($debugLevel -ge 2) {
                    Write-Host "  [task-parity] Parse attempt $retryCount failed, retrying..." -ForegroundColor Yellow
                }
                Start-Sleep -Milliseconds (100 * $retryCount)
            }
        }
    }
}

Write-Host ""

# Compare tasks
Write-Host "Comparing tasks..." -ForegroundColor Yellow
try {
    $comparison = Compare-Tasks -TaskSets $allTasks
    if ($debugLevel -ge 2) {
        Write-Host "  [task-parity] Comparison completed" -ForegroundColor DarkGray
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName "task-parity.compare" -Context @{
            task_file_count = $allTasks.Count
        }
    }
    else {
        Write-Error "Failed to compare tasks: $_"
    }
    # Use Exit-WithCode if available, otherwise use numeric exit code
    if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
        try {
            Exit-WithCode -ExitCode [ExitCode]::RuntimeError -ErrorRecord $_
        }
        catch {
            exit 3
        }
    }
    else {
        exit 3
    }
}

# Display results
Write-Host "`nTask Parity Report" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""

# Summary statistics with validation
Write-Host "Summary:" -ForegroundColor Yellow
try {
    $totalTasks = if ($comparison.AllTasks) {
        ($comparison.AllTasks | Measure-Object).Count
    }
    else {
        0
    }
    $uniqueTasks = if ($comparison.AllTasks) {
        ($comparison.AllTasks | Select-Object -Unique | Measure-Object).Count
    }
    else {
        0
    }
    Write-Host "  Total task definitions: $totalTasks" -ForegroundColor White
    Write-Host "  Unique task names: $uniqueTasks" -ForegroundColor White
    
    # Additional statistics
    if ($debugLevel -ge 2) {
        $filesWithTasks = ($allTasks.Keys | Where-Object { $allTasks[$_].Count -gt 0 }).Count
        Write-Host "  [task-parity] Files with tasks: $filesWithTasks/$($allTasks.Count)" -ForegroundColor DarkGray
    }
    Write-Host ""
}
catch {
    if ($debugLevel -ge 1) {
        Write-Host "  [task-parity] Error calculating statistics: $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Missing tasks per file with validation
Write-Host "Missing Tasks by File:" -ForegroundColor Yellow
if ($comparison.MissingTasks) {
    foreach ($fileType in $comparison.MissingTasks.Keys) {
        try {
            $missing = $comparison.MissingTasks[$fileType]
            if ($null -eq $missing) {
                $missing = @()
            }
            if ($missing.Count -gt 0) {
                Write-Host "  $fileType : $($missing.Count) missing" -ForegroundColor Red
                foreach ($taskName in $missing) {
                    if (-not [string]::IsNullOrWhiteSpace($taskName)) {
                        Write-Host "    - $taskName" -ForegroundColor DarkGray
                    }
                }
            }
            else {
                Write-Host "  $fileType : No missing tasks" -ForegroundColor Green
            }
        }
        catch {
            if ($debugLevel -ge 1) {
                Write-Host "  [task-parity] Error processing missing tasks for $fileType : $_" -ForegroundColor Yellow
            }
            Write-Host "  $fileType : Error processing" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "  Unable to determine missing tasks (comparison data incomplete)" -ForegroundColor Yellow
}
Write-Host ""

# Command differences with validation
if ($comparison.CommandDifferences -and $comparison.CommandDifferences.Count -gt 0) {
    Write-Host "Command Differences:" -ForegroundColor Yellow
    foreach ($taskName in $comparison.CommandDifferences.Keys) {
        try {
            $diffs = $comparison.CommandDifferences[$taskName]
            if ($null -ne $diffs) {
                Write-Host "  $taskName" -ForegroundColor Magenta
                foreach ($fileType in $diffs.Keys) {
                    $diffValue = $diffs[$fileType]
                    if (-not [string]::IsNullOrWhiteSpace($diffValue)) {
                        # Truncate very long command differences for readability
                        $displayValue = if ($diffValue.Length -gt 100) {
                            $diffValue.Substring(0, 97) + "..."
                        }
                        else {
                            $diffValue
                        }
                        Write-Host "    $fileType : $displayValue" -ForegroundColor DarkGray
                    }
                }
            }
        }
        catch {
            if ($debugLevel -ge 1) {
                Write-Host "  [task-parity] Error processing command differences for $taskName : $_" -ForegroundColor Yellow
            }
        }
    }
    Write-Host ""
}

# Generate missing tasks if requested
if ($Generate) {
    # Check if TaskGenerator is available
    if (-not $parserModules.TaskGenerator) {
        $errorMsg = "TaskGenerator module is required for -Generate but is not available. Cannot generate missing tasks."
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                [System.Management.Automation.ItemNotFoundException]::new($errorMsg),
                'TaskGeneratorNotFound',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'TaskGenerator'
            )) -OperationName "task-parity.generate" -Context @{
                generate_requested = $true
            }
        }
        else {
            Write-Error $errorMsg
        }
        if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
            try {
                Exit-WithCode -ExitCode [ExitCode]::SetupError -Message $errorMsg
            }
            catch {
                exit 2
            }
        }
        else {
            exit 2
        }
    }
    Write-Host "Generating missing tasks..." -ForegroundColor Yellow
    
    $filesToUpdate = if ($TargetFile -eq 'all') {
        @('taskfile', 'makefile', 'package', 'justfile', 'tasksjson')
    }
    else {
        @($TargetFile)
    }
    
    foreach ($fileType in $filesToUpdate) {
        if (-not $allTasks.ContainsKey($fileType)) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Skipping file - not found or not parsed" -OperationName "task-parity.generate" -Context @{
                    file_type = $fileType
                } -Code "FILE_SKIPPED"
            }
            else {
                Write-Warning "Skipping $fileType - file not found or not parsed"
            }
            continue
        }
        
        $missing = $comparison.MissingTasks[$fileType]
        if ($missing.Count -eq 0) {
            Write-Host "  $fileType : No missing tasks to generate" -ForegroundColor Green
            continue
        }
        
        $filePath = $taskFiles[$fileType]
        Write-Host "  Generating $($missing.Count) tasks in $fileType..." -ForegroundColor Yellow
        
        try {
            $referenceTasks = $allTasks['taskfile']  # Use Taskfile.yml as reference
            if (-not $referenceTasks -or $referenceTasks.Count -eq 0) {
                # Fallback to first available task set with most tasks
                $referenceTasks = ($allTasks.Values | Where-Object { $null -ne $_ -and $_.Count -gt 0 } | Sort-Object { $_.Count } -Descending | Select-Object -First 1)
            }
            
            if ($referenceTasks -and $referenceTasks.Count -gt 0) {
                if ($debugLevel -ge 2) {
                    Write-Host "  [task-parity] Generating $($missing.Count) tasks in $fileType using $($referenceTasks.Count) reference tasks" -ForegroundColor DarkGray
                }
                
                # Validate file is writable before attempting generation
                try {
                    $fileInfo = Get-Item -LiteralPath $filePath -ErrorAction Stop
                    if ($fileInfo.IsReadOnly) {
                        throw "File is read-only: $filePath"
                    }
                    
                    # Create backup if file exists and is not empty
                    if ($fileInfo.Length -gt 0) {
                        $backupPath = "$filePath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
                        try {
                            Copy-Item -LiteralPath $filePath -Destination $backupPath -ErrorAction Stop
                            if ($debugLevel -ge 2) {
                                Write-Host "  [task-parity] Created backup: $backupPath" -ForegroundColor DarkGray
                            }
                        }
                        catch {
                            if ($debugLevel -ge 1) {
                                Write-Host "  [task-parity] Warning: Could not create backup: $_" -ForegroundColor Yellow
                            }
                            # Continue even if backup fails
                        }
                    }
                    
                    # Validate that we have reference data for all missing tasks
                    $missingWithRefs = @()
                    $missingWithoutRefs = @()
                    foreach ($taskName in $missing) {
                        if ($referenceTasks.ContainsKey($taskName)) {
                            $missingWithRefs += $taskName
                        }
                        else {
                            $missingWithoutRefs += $taskName
                        }
                    }
                    
                    if ($missingWithoutRefs.Count -gt 0) {
                        if ($debugLevel -ge 1) {
                            Write-Host "  [task-parity] Warning: $($missingWithoutRefs.Count) tasks have no reference data: $($missingWithoutRefs -join ', ')" -ForegroundColor Yellow
                        }
                    }
                    
                    if ($missingWithRefs.Count -gt 0) {
                        # Verify Add-MissingTasks function is available
                        if (-not (Get-Command Add-MissingTasks -ErrorAction SilentlyContinue)) {
                            throw "Add-MissingTasks function is not available. TaskGenerator module may not be loaded."
                        }
                        
                        Add-MissingTasks -FilePath $filePath -FileType $fileType -MissingTaskNames $missingWithRefs -ReferenceTasks $referenceTasks
                        Write-Host "    Successfully generated $($missingWithRefs.Count) tasks in $fileType" -ForegroundColor Green
                        if ($missingWithoutRefs.Count -gt 0) {
                            Write-Host "    Skipped $($missingWithoutRefs.Count) tasks without reference data" -ForegroundColor Yellow
                        }
                    }
                    else {
                        throw "No tasks have reference data available for generation"
                    }
                }
                catch {
                    throw "Failed to generate tasks: $_"
                }
            }
            else {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "No reference tasks available" -OperationName "task-parity.generate" -Context @{
                        file_type = $fileType
                        missing_count = $missing.Count
                    } -Code "NO_REFERENCE_TASKS"
                }
                else {
                    Write-Warning "    No reference tasks available for $fileType"
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "task-parity.generate" -Context @{
                    file_type = $fileType
                    file_path = $filePath
                    missing_count = $missing.Count
                }
            }
            else {
                Write-Error "    Failed to generate tasks in $fileType : $_"
            }
            if ($debugLevel -ge 2) {
                Write-Host "  [task-parity] Generation error details: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
            }
        }
    }
    
    Write-Host ""
    Write-Host "Task generation complete. Please review the changes before committing." -ForegroundColor Yellow
}

# Exit with appropriate code (with validation)
$hasMissingTasks = $false
try {
    if ($comparison.MissingTasks) {
        $missingCounts = $comparison.MissingTasks.Values | Where-Object { $null -ne $_ -and $_.Count -gt 0 }
        $hasMissingTasks = ($missingCounts | Measure-Object).Count -gt 0
    }
}
catch {
    if ($debugLevel -ge 1) {
        Write-Host "  [task-parity] Error checking for missing tasks: $_" -ForegroundColor Yellow
    }
    # If we can't determine, assume there are differences to be safe
    $hasMissingTasks = $true
}

if ($hasMissingTasks) {
    if (-not $Generate) {
        Write-Host "`nTip: Use -Generate to automatically add missing tasks." -ForegroundColor Cyan
    }
    # Use Exit-WithCode if available, otherwise use numeric exit code
    if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
        try {
            Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Task parity check found differences"
        }
        catch {
            exit 1
        }
    }
    else {
        exit 1
    }
}
else {
    Write-Host "`n✓ All task files have parity!" -ForegroundColor Green
    if ($debugLevel -ge 1) {
        Write-Host "  [task-parity] All task files have parity" -ForegroundColor DarkGray
    }
    # Use Exit-WithCode if available, otherwise use numeric exit code
    if ($importedModules.ExitCodes -and (Get-Command Exit-WithCode -ErrorAction SilentlyContinue)) {
        try {
            Exit-WithCode -ExitCode [ExitCode]::Success
        }
        catch {
            exit 0
        }
    }
    else {
        exit 0
    }
}
