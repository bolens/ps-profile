<#
scripts/utils/task-parity/modules/TaskComparator.psm1

.SYNOPSIS
    Compares task definitions across multiple task runner files.

.DESCRIPTION
    Provides functions to compare tasks and identify:
    - Missing tasks in each file
    - Command differences for the same task
    - Summary statistics

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 5.0+
#>

$utilitiesModulePath = Join-Path $PSScriptRoot 'TaskParityUtilities.psm1'
if (Test-Path -LiteralPath $utilitiesModulePath) {
    Import-Module $utilitiesModulePath -DisableNameChecking -Force
}

function Compare-Tasks {
    <#
.SYNOPSIS
        Compares tasks across multiple task runner files.
    
    .DESCRIPTION
        Analyzes task definitions and identifies missing tasks and command differences.
    
    .PARAMETER TaskSets
        Hashtable mapping file types to their task definitions.
        Format: @{ 'taskfile' = @{ 'task1' = @{ Command = '...'; Description = '...' } }; ... }
    
    .OUTPUTS
        Hashtable with comparison results:
        - AllTasks: Array of all unique task names
        - MissingTasks: Hashtable mapping file types to arrays of missing task names
        - CommandDifferences: Hashtable mapping task names to command differences
.EXAMPLE
    Compare-Tasks -TaskSets $taskSets

#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TaskSets
    )
    
    # Collect all unique task names
    $allTaskNames = @()
    foreach ($fileType in $TaskSets.Keys) {
        $tasks = $TaskSets[$fileType]
        foreach ($taskName in $tasks.Keys) {
            if ($taskName -notin $allTaskNames) {
                $allTaskNames += $taskName
            }
        }
    }
    
    # Find missing tasks per file
    $missingTasks = @{}
    foreach ($fileType in $TaskSets.Keys) {
        $tasks = $TaskSets[$fileType]
        $missing = @()
        foreach ($taskName in $allTaskNames) {
            if (-not $tasks.ContainsKey($taskName)) {
                $missing += $taskName
            }
        }
        $missingTasks[$fileType] = $missing
    }
    
    # Find command differences
    $commandDifferences = @{}
    foreach ($taskName in $allTaskNames) {
        $commands = @{}
        foreach ($fileType in $TaskSets.Keys) {
            $tasks = $TaskSets[$fileType]
            if ($tasks.ContainsKey($taskName)) {
                $cmd = $tasks[$taskName].Command
                # Normalize command for comparison (remove whitespace differences)
                $normalized = Normalize-Command -Command $cmd
                $commands[$fileType] = $normalized
            }
        }
        
        # Check if commands differ
        $uniqueCommands = ($commands.Values | Select-Object -Unique)
        if ($uniqueCommands.Count -gt 1) {
            $commandDifferences[$taskName] = $commands
        }
    }
    
    return @{
        AllTasks = $allTaskNames
        MissingTasks = $missingTasks
        CommandDifferences = $commandDifferences
    }
}

function Normalize-Command {
    <#
.SYNOPSIS
        Normalizes a command string for comparison.
    
    .DESCRIPTION
        Removes whitespace differences and normalizes variable/argument placeholders.
.PARAMETER Command
    Shell command text.
.EXAMPLE
    Normalize-Command -Command 'pwsh -NoProfile -File scripts/test.ps1'

#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )
    
    if ([string]::IsNullOrWhiteSpace($Command)) {
        return ''
    }
    
    # Normalize whitespace
    $normalized = $Command -replace '\s+', ' ' -replace '\r\n', ' ' -replace '\n', ' ' -replace '\r', ' '
    $normalized = $normalized.Trim()
    
    # Normalize common argument placeholders
    # Taskfile: {{.CLI_ARGS}}
    # Makefile: $(ARGS)
    # Justfile: {{arguments()}}
    # package.json: (no args)
    $normalized = $normalized -replace '\{\{\.CLI_ARGS\}\}', '{{ARGS}}'
    $normalized = $normalized -replace '\$\(ARGS\)', '{{ARGS}}'
    $normalized = $normalized -replace '\{\{arguments\(\)\}\}', '{{ARGS}}'
    $normalized = $normalized -replace '\$\{workspaceFolder\}[\\/]', '${workspaceFolder}/'

    if (Get-Command Normalize-TaskScriptPathInText -ErrorAction SilentlyContinue) {
        $normalized = Normalize-TaskScriptPathInText -Text $normalized
    }
    else {
        $normalized = $normalized -replace '\\', '/'
    }
    
    return $normalized
}

Export-ModuleMember -Function Compare-Tasks, Normalize-Command
