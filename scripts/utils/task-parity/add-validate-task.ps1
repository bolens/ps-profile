<#
.SYNOPSIS
    Adds the validate task to all task runner files using the task-parity utilities.

.DESCRIPTION
    Uses the Add-MissingTasks function from TaskGenerator.psm1 to ensure the validate
    task is properly added to Taskfile.yml, Makefile, package.json, justfile, and
    .vscode/tasks.json with consistent formatting.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/task-parity/add-validate-task.ps1
    
    Adds the validate task to all task runner files.
#>

[CmdletBinding(SupportsShouldProcess)]
param()

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if (Test-Path -LiteralPath $pathResolutionPath) {
    Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Resolve repository root
$repoRoot = $null
if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
    try {
        $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    catch {
        # Fallback: manually calculate repo root
        $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    }
}
else {
    # Fallback: manually calculate repo root
    $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

# Import task-parity modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
$taskParserPath = Join-Path $modulesPath 'TaskParser.psm1'
$taskGeneratorPath = Join-Path $modulesPath 'TaskGenerator.psm1'

if (-not (Test-Path -LiteralPath $taskParserPath)) {
    Write-Error "TaskParser module not found: $taskParserPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $taskGeneratorPath)) {
    Write-Error "TaskGenerator module not found: $taskGeneratorPath"
    exit 1
}

Import-Module $taskParserPath -DisableNameChecking -ErrorAction Stop
Import-Module $taskGeneratorPath -DisableNameChecking -ErrorAction Stop

Write-Host "Adding validate task to all task runner files..." -ForegroundColor Cyan
Write-Host ""

# Define the validate task (using Taskfile.yml as the reference)
$validateTask = @{
    Command     = 'pwsh -NoProfile -File scripts/checks/validate-profile.ps1'
    Description = 'Validate profile (lint + idempotency)'
}

# Create reference tasks hashtable
$referenceTasks = @{
    'validate' = $validateTask
}

# Define task files to update
$taskFiles = @(
    @{ Path = Join-Path $repoRoot 'Taskfile.yml'; Type = 'taskfile' }
    @{ Path = Join-Path $repoRoot 'Makefile'; Type = 'makefile' }
    @{ Path = Join-Path $repoRoot 'package.json'; Type = 'package' }
    @{ Path = Join-Path $repoRoot 'justfile'; Type = 'justfile' }
    @{ Path = Join-Path $repoRoot '.vscode' 'tasks.json'; Type = 'tasksjson' }
)

$addedCount = 0
$skippedCount = 0

foreach ($taskFile in $taskFiles) {
    $filePath = $taskFile.Path
    $fileType = $taskFile.Type
    
    if (-not (Test-Path -LiteralPath $filePath)) {
        Write-Host "  ⚠ Skipping ${fileType}: File not found at $filePath" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    # Check if task already exists
    try {
        $existingTasks = Get-TasksFromFile -FilePath $filePath -FileType $fileType
        if ($existingTasks.ContainsKey('validate')) {
            Write-Host "  ✓ ${fileType}: validate task already exists" -ForegroundColor Green
            $skippedCount++
            continue
        }
    }
    catch {
        Write-Host "  ⚠ ${fileType}: Could not parse existing tasks, will attempt to add anyway" -ForegroundColor Yellow
    }
    
    # Add the task
    try {
        if ($PSCmdlet.ShouldProcess($filePath, "Add validate task to ${fileType}")) {
            Add-MissingTasks -FilePath $filePath -FileType $fileType -MissingTaskNames @('validate') -ReferenceTasks $referenceTasks
            Write-Host "  ✓ ${fileType}: Added validate task" -ForegroundColor Green
            $addedCount++
        }
    }
    catch {
        Write-Host "  ✗ ${fileType}: Failed to add validate task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Added: $addedCount" -ForegroundColor $(if ($addedCount -gt 0) { 'Green' } else { 'Gray' })
Write-Host "  Already present: $skippedCount" -ForegroundColor Gray
Write-Host ""

if ($addedCount -gt 0) {
    Write-Host "✓ Validate task has been added to all task runner files" -ForegroundColor Green
}
else {
    Write-Host "✓ Validate task already exists in all task runner files" -ForegroundColor Green
}

exit 0
