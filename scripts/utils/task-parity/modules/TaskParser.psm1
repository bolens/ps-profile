<#
scripts/utils/task-parity/modules/TaskParser.psm1

.SYNOPSIS
    Parses task definitions from various task runner file formats.

.DESCRIPTION
    Provides functions to parse tasks from:
    - Taskfile.yml (YAML format)
    - Makefile (Make format)
    - package.json (JSON format)
    - justfile (Just format)
    - .vscode/tasks.json (VS Code tasks format)

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 5.0+
#>

$utilitiesModulePath = Join-Path $PSScriptRoot 'TaskParityUtilities.psm1'
if (Test-Path -LiteralPath $utilitiesModulePath) {
    Import-Module $utilitiesModulePath -DisableNameChecking -Force
}

function Get-TasksFromFile {
    <#
.SYNOPSIS
        Parses tasks from a task runner file.
    
    .DESCRIPTION
        Extracts task names and their commands from various task runner file formats.
    
    .PARAMETER FilePath
        Path to the task file.
    
    .PARAMETER FileType
        Type of task file: 'taskfile', 'makefile', 'package', 'justfile', or 'tasksjson'.
    
    .OUTPUTS
        Hashtable mapping task names to their command strings.
.EXAMPLE
    Get-TasksFromFile -FilePath ./Taskfile.yml -FileType taskfile
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [ValidateSet('taskfile', 'makefile', 'package', 'justfile', 'tasksjson')]
        [string]$FileType
    )
    
    if (-not (Test-Path -LiteralPath $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    $tasks = @{}
    
    switch ($FileType) {
        'taskfile' {
            $tasks = Get-TasksFromTaskfile -FilePath $FilePath
        }
        'makefile' {
            $tasks = Get-TasksFromMakefile -FilePath $FilePath
        }
        'package' {
            $tasks = Get-TasksFromPackageJson -FilePath $FilePath
        }
        'justfile' {
            $tasks = Get-TasksFromJustfile -FilePath $FilePath
        }
        'tasksjson' {
            throw 'Get-TasksFromFile does not support tasksjson; call Get-TasksFromTasksJson with -ReferenceTasks instead.'
        }
    }
    
    return $tasks
}

function Get-TasksFromTaskfile {
    <#
.SYNOPSIS
        Parses tasks from Taskfile.yml.

.DESCRIPTION
        Parses tasks from Taskfile.yml.

.PARAMETER FilePath
        Path to the target file.
.EXAMPLE
    Get-TasksFromTaskfile -FilePath ./Taskfile.yml
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    $tasks = @{}
    $content = Get-Content -Path $FilePath -Raw
    
    # Simple YAML parsing for Taskfile.yml format
    # Taskfile.yml can have two formats:
    # 1. Root-level tasks: task-name: ... desc: ... cmds: ...
    # 2. tasks: section with indented tasks (version 3+)
    $lines = Get-Content -Path $FilePath
    $currentTask = $null
    $currentDesc = $null
    $inCmds = $false
    $inDeps = $false
    $inTasksSection = $false
    $cmdLines = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmed = $line.TrimEnd()
        
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        
        # Check if we're entering the tasks: section
        if ($trimmed -match '^tasks:\s*$') {
            $inTasksSection = $true
            continue
        }
        
        # Determine indentation level
        $indentLevel = 0
        if ($trimmed -match '^(\s+)') {
            $indentLevel = $matches[1].Length
        }
        
        # Check for task definition
        # For tasks: section format, tasks are indented 2 spaces
        # For root-level format, tasks have no or minimal indentation
        if ($trimmed -match '^(\s*)([a-zA-Z0-9_-]+):\s*(.*)$') {
            $taskIndent = $matches[1].Length
            $taskName = $matches[2]
            $taskValue = $matches[3]
            
            # Skip version and tasks keys
            if ($taskName -eq 'version' -or $taskName -eq 'tasks') {
                continue
            }
            
            # Check if this is a task definition
            # In tasks: section, tasks are indented 2 spaces
            # At root level, tasks have no indentation (or minimal)
            $isTaskDefinition = $false
            if ($inTasksSection) {
                # In tasks section, tasks are indented 2 spaces
                $isTaskDefinition = ($taskIndent -eq 2)
            }
            else {
                # Root level tasks have no or minimal indentation
                $isTaskDefinition = ($taskIndent -le 1)
            }
            
            if ($isTaskDefinition) {
                # Save previous task if exists
            if ($currentTask) {
                $cmd = Join-TaskCommandLines -Lines $cmdLines
                if ($cmd) {
                    $tasks[$currentTask] = @{
                        Command     = $cmd
                        Description = $currentDesc
                    }
                }
            }
            
            # Start new task
            $currentTask = $taskName
                $currentDesc = $taskValue
                $inCmds = $false
                $inDeps = $false
                $cmdLines = @()
                continue
            }
        }
        
        # Check for cmds: section (indented 4 spaces in tasks section, or 2 spaces at root)
        if ($currentTask -and ($trimmed -match '^(\s+)cmds:\s*$')) {
            $indent = $matches[1].Length
            # cmds: should be indented 4 spaces under tasks section, or 2 spaces at root
            if (($inTasksSection -and $indent -eq 4) -or (-not $inTasksSection -and $indent -eq 2)) {
                $inCmds = $true
                $inDeps = $false
                continue
            }
        }
        
        # Check for deps: section (skip it)
        if ($currentTask -and ($trimmed -match '^(\s+)deps:\s*')) {
            $indent = $matches[1].Length
            if (($inTasksSection -and $indent -eq 4) -or (-not $inTasksSection -and $indent -eq 2)) {
                $inDeps = $true
                $inCmds = $false
                continue
            }
        }
        
        # Check for command lines (indented with - or spaces, only in cmds section)
        if ($inCmds -and $currentTask) {
            # Commands are indented 6 spaces in tasks section (4 for cmds: + 2 for -), or 4 spaces at root
            if ($trimmed -match '^(\s+)-\s+(.+)$') {
                $indent = $matches[1].Length
                $cmd = $matches[2]
                # In tasks section, commands are indented 6 spaces (4 for cmds: level + 2 for list item)
                # At root level, commands are indented 4 spaces (2 for cmds: level + 2 for list item)
                if (($inTasksSection -and $indent -eq 6) -or (-not $inTasksSection -and $indent -eq 4)) {
                    if ($cmd -and -not $cmd.StartsWith('desc:') -and -not $cmd.StartsWith('deps:')) {
                        $cmdLines += $cmd
                    }
                    continue
                }
            }
        }
        
        # Check for desc: line (indented 4 spaces in tasks section, or 2 spaces at root)
        if ($currentTask -and $trimmed -match '^(\s+)desc:\s*(.+)$') {
            $indent = $matches[1].Length
            if (($inTasksSection -and $indent -eq 4) -or (-not $inTasksSection -and $indent -eq 2)) {
                $currentDesc = $matches[2]
                continue
            }
        }
        
        # If we hit a line with less indentation (back to task level or out of tasks section), reset
        if ($currentTask) {
            if ($inTasksSection) {
                # In tasks section, if we hit a line with 2 spaces or less (back to task level or out)
                if ($indentLevel -le 2 -and -not $trimmed.StartsWith('    ')) {
                    $inCmds = $false
                    $inDeps = $false
                }
            }
            else {
                # At root level, if we hit a non-indented line, we've left the task
                if ($indentLevel -eq 0 -and -not [string]::IsNullOrWhiteSpace($trimmed)) {
                    $inCmds = $false
                    $inDeps = $false
                }
            }
        }
    }
    
    # Save last task
    if ($currentTask) {
        $cmd = Join-TaskCommandLines -Lines $cmdLines
        if ($cmd) {
            $tasks[$currentTask] = @{
                Command     = $cmd
                Description = $currentDesc
            }
        }
    }
    
    return $tasks
}

function Get-TasksFromMakefile {
    <#
.SYNOPSIS
        Parses tasks from Makefile.

.DESCRIPTION
        Parses tasks from Makefile.

.PARAMETER FilePath
        Path to the target file.
.EXAMPLE
    Get-TasksFromMakefile -FilePath ./Taskfile.yml
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    $tasks = @{}
    $lines = Get-Content -Path $FilePath
    
    $currentTask = $null
    $currentDesc = $null
    $cmdLines = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmed = $line.TrimEnd()
        
        # Skip empty lines and comments (unless they're descriptions)
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }
        
        # Check for task definition (target: dependencies ## description)
        if ($trimmed -match '^([a-zA-Z0-9_-]+):\s*(.*?)(?:\s+##\s*(.+))?$') {
            # Save previous task
            if ($currentTask) {
                $cmd = Join-TaskCommandLines -Lines $cmdLines
                if ($cmd) {
                    $tasks[$currentTask] = @{
                        Command     = $cmd
                        Description = $currentDesc
                    }
                }
            }
            
            # Start new task
            $currentTask = $matches[1]
            $currentDesc = if ($matches[3]) { $matches[3] } else { $null }
            $cmdLines = @()
        }
        # Check for command lines (must start with tab)
        elseif ($currentTask -and $line -match '^\t(.+)$') {
            $cmdLines += $matches[1]
        }
        # Check for description in comment (## description)
        elseif ($trimmed -match '^##\s*(.+)$' -and $currentTask) {
            $currentDesc = $matches[1]
        }
    }
    
    # Save last task
    if ($currentTask) {
        $cmd = Join-TaskCommandLines -Lines $cmdLines
        if ($cmd) {
            $tasks[$currentTask] = @{
                Command     = $cmd
                Description = $currentDesc
            }
        }
    }
    
    return $tasks
}

function Get-TasksFromPackageJson {
    <#
.SYNOPSIS
        Parses tasks from package.json scripts section.

.DESCRIPTION
        Parses tasks from package.json scripts section.

.PARAMETER FilePath
        Path to the target file.
.EXAMPLE
    Get-TasksFromPackageJson -FilePath ./Taskfile.yml
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    $tasks = @{}
    
    try {
        # Read file with error handling
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Warning "package.json is empty: $FilePath"
            return $tasks
        }
        
        # Parse JSON with error handling
        $json = $content | ConvertFrom-Json -ErrorAction Stop
        
        if ($null -eq $json) {
            Write-Warning "Failed to parse package.json: JSON conversion returned null"
            return $tasks
        }
        
        if ($json.scripts) {
            foreach ($taskName in $json.scripts.PSObject.Properties.Name) {
                if (-not [string]::IsNullOrWhiteSpace($taskName)) {
                    $command = $json.scripts.$taskName
                    if (-not [string]::IsNullOrWhiteSpace($command)) {
                        $tasks[$taskName] = @{
                            Command     = (Normalize-TaskScriptPathInText -Text $command)
                            Description = $null  # package.json doesn't have descriptions
                        }
                    }
                }
            }
        }
    }
    catch {
        $errorMsg = "Failed to parse package.json: $_"
        Write-Warning $errorMsg
        # Return empty tasks rather than throwing to allow script to continue
    }
    
    return $tasks
}

function Get-TasksFromJustfile {
    <#
.SYNOPSIS
        Parses tasks from justfile.

.DESCRIPTION
        Parses tasks from justfile.

.PARAMETER FilePath
        Path to the target file.
.EXAMPLE
    Get-TasksFromJustfile -FilePath ./Taskfile.yml
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    $tasks = @{}
    $lines = Get-Content -Path $FilePath
    
    $currentTask = $null
    $currentDesc = $null
    $cmdLines = @()
    $inTask = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmed = $line.TrimEnd()
        
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }
        
        # Check for comment description (before task)
        if ($trimmed.StartsWith('#') -and -not $trimmed.StartsWith('##')) {
            $currentDesc = $trimmed.TrimStart('#').TrimStart()
        }
        # Check for task definition (task-name: or task-name dependency1 dependency2:)
        elseif ($trimmed -match '^([a-zA-Z0-9_-]+)(?:\s+[a-zA-Z0-9_-]+)*:\s*$') {
            # Save previous task
            if ($currentTask) {
                $cmd = Join-TaskCommandLines -Lines $cmdLines
                if ($cmd) {
                    $tasks[$currentTask] = @{
                        Command     = $cmd
                        Description = $currentDesc
                    }
                }
            }
            
            # Start new task
            $currentTask = $matches[1]
            $cmdLines = @()
            $inTask = $true
        }
        # Check for command lines (not starting with # and not empty)
        elseif ($inTask -and -not $trimmed.StartsWith('#') -and -not [string]::IsNullOrWhiteSpace($trimmed)) {
            $cmdLines += $trimmed
        }
        # If we hit a line that starts a new task or is a comment at root level, we've left the task
        elseif ($inTask -and ($trimmed -match '^[a-zA-Z0-9_-]+:' -or ($trimmed.StartsWith('#') -and -not $trimmed.StartsWith('##')))) {
            $inTask = $false
        }
    }
    
    # Save last task
    if ($currentTask) {
        $cmd = Join-TaskCommandLines -Lines $cmdLines
        if ($cmd) {
            $tasks[$currentTask] = @{
                Command     = $cmd
                Description = $currentDesc
            }
        }
    }
    
    return $tasks
}

function Get-TaskCommandSignature {
    <#
.SYNOPSIS
        Builds a comparable signature from a task command (script path plus key flags).

.DESCRIPTION
        Builds a comparable signature from a task command (script path plus key flags).

.PARAMETER Command
        Shell command text.
.EXAMPLE
    Get-TaskCommandSignature -Command 'pwsh -NoProfile -File scripts/test.ps1'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Command
    )

    $scriptPath = Get-ScriptPathFromTaskCommand -Command $Command
    if (-not $scriptPath) {
        return $null
    }

    $signatureParts = @($scriptPath)
    $normalized = $Command -replace '\\', '/'
    $normalized = $normalized -replace '\{\{[^}]+\}\}', ''
    $normalized = $normalized -replace '\$\([^)]+\)', ''
    $normalized = $normalized -replace '\$\{[^}]+\}', ''

    foreach ($flag in @('-Suite', '-Action', '-UpdateBaseline', '-TestOperations')) {
        if ($normalized -match "$flag(?:\s|=)([^\s]+)?" -or $normalized -match "$flag\b") {
            if ($Matches[1]) {
                $signatureParts += "$flag=$($Matches[1])"
            }
            else {
                $signatureParts += $flag
            }
        }
    }

    if ($normalized -match '(?<![\w-])-Update(?![\w-])') {
        $signatureParts += '-Update'
    }

    if ($normalized -match '(?<![\w-])-DryRun(?![\w-])') {
        $signatureParts += '-DryRun'
    }

    if ($normalized -match '(?<![\w-])-Coverage(?![\w-])') {
        $signatureParts += '-Coverage'
    }

    if ($normalized -match '(?<![\w-])-Parallel(?![\w-])') {
        $signatureParts += '-Parallel'
    }

    if ($normalized -match '(?<![\w-])-Generate(?![\w-])') {
        $signatureParts += '-Generate'
    }

    return ($signatureParts -join '|').ToLowerInvariant()
}

function Get-ScriptPathFromTaskCommand {
    <#
.SYNOPSIS
        Extracts the scripts/*.ps1 path from a task command string.

.DESCRIPTION
        Extracts the scripts/*.ps1 path from a task command string.

.PARAMETER Command
        Shell command text.
.EXAMPLE
    Get-ScriptPathFromTaskCommand -Command 'pwsh -NoProfile -File scripts/test.ps1'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $null
    }

    $normalized = $Command -replace '\\', '/'
    if ($normalized -match '(scripts/[^\s"''`]+\.ps1)') {
        return $Matches[1]
    }

    return $null
}

function Resolve-CanonicalTaskNameFromVsCodeTask {
    <#
.SYNOPSIS
        Maps a VS Code task label/command to a canonical task runner name.

.DESCRIPTION
        Maps a VS Code task label/command to a canonical task runner name.

.PARAMETER Label
        Task label used in tasks.json output.

.PARAMETER Command
        Shell command text.

.PARAMETER ReferenceTasks
        Reference task metadata keyed by task name.
.EXAMPLE
    Resolve-CanonicalTaskNameFromVsCodeTask -Label 'test' -Command 'pwsh -NoProfile -File scripts/test.ps1' -ReferenceTasks $refTasks
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Command,

        [Parameter(Mandatory)]
        [hashtable]$ReferenceTasks
    )

    if ($ReferenceTasks.ContainsKey($Label)) {
        return $Label
    }

    $signature = Get-TaskCommandSignature -Command $Command
    if ($signature) {
        foreach ($taskName in $ReferenceTasks.Keys) {
            $refSignature = Get-TaskCommandSignature -Command $ReferenceTasks[$taskName].Command
            if ($refSignature -and $refSignature -eq $signature) {
                return $taskName
            }
        }
    }

    return $Label
}

function Convert-TasksJsonToCanonicalNames {
    <#
.SYNOPSIS
        Re-keys VS Code tasks by canonical task names using reference task commands.

.DESCRIPTION
        Re-keys VS Code tasks by canonical task names using reference task commands.

.PARAMETER Tasks
        Parsed task objects to compare or serialize.

.PARAMETER ReferenceTasks
        Reference task metadata keyed by task name.
.EXAMPLE
    Convert-TasksJsonToCanonicalNames -Tasks $tasks -ReferenceTasks $refTasks
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tasks,

        [Parameter(Mandatory)]
        [hashtable]$ReferenceTasks
    )

    $canonical = @{}

    foreach ($taskName in $Tasks.Keys) {
        $task = $Tasks[$taskName]
        $canonicalName = Resolve-CanonicalTaskNameFromVsCodeTask -Label $taskName -Command $task.Command -ReferenceTasks $ReferenceTasks

        if (-not $canonical.ContainsKey($canonicalName)) {
            $canonical[$canonicalName] = $task
        }
    }

    return $canonical
}

function Get-TasksFromTasksJson {
    <#
.SYNOPSIS
        Parses tasks from VS Code tasks.json file.

.DESCRIPTION
        Parses tasks from VS Code tasks.json file.

.PARAMETER FilePath
        Path to the target file.

.PARAMETER ReferenceTasks
        Reference task metadata keyed by task name.
.EXAMPLE
    Get-TasksFromTasksJson -FilePath ./Taskfile.yml
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [hashtable]$ReferenceTasks = $null
    )
    
    $tasks = @{}
    
    try {
        # Read file with error handling
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Warning "tasks.json is empty: $FilePath"
            return $tasks
        }
        
        # Parse JSON with error handling
        $json = $content | ConvertFrom-Json -ErrorAction Stop
        
        if ($null -eq $json) {
            Write-Warning "Failed to parse tasks.json: JSON conversion returned null"
            return $tasks
        }
        
        # VS Code tasks.json has a "tasks" array
        if ($json.tasks -and $json.tasks.Count -gt 0) {
            foreach ($task in $json.tasks) {
                if (-not $task.label -or [string]::IsNullOrWhiteSpace($task.label)) {
                    continue
                }
                
                $label = $task.label
                $command = $null
                
                # Build command from task definition
                if ($task.type -eq 'shell' -or $task.type -eq 'process') {
                    # For shell/process tasks, combine command and args
                    if ($task.command) {
                        $cmdParts = @($task.command)
                        
                        # Add args if present
                        if ($task.args -and $task.args.Count -gt 0) {
                            foreach ($arg in $task.args) {
                                # Replace VS Code variables with placeholders
                                $argStr = $arg -replace '\$\{workspaceFolder\}', '${workspaceFolder}'
                                $argStr = $argStr -replace '\$\{([^}]+)\}', '${$1}'
                                $cmdParts += $argStr
                            }
                        }
                        
                        $command = Normalize-TaskScriptPathInText -Text ($cmdParts -join ' ')
                    }
                    elseif ($task.command -is [string]) {
                        $command = Normalize-TaskScriptPathInText -Text $task.command
                    }
                }
                elseif ($task.command) {
                    $command = Normalize-TaskScriptPathInText -Text $task.command
                }
                
                # Only add task if it has a command (skip composite tasks that only have dependsOn)
                if (-not [string]::IsNullOrWhiteSpace($command)) {
                    $taskName = $label
                    if ($ReferenceTasks) {
                        $taskName = Resolve-CanonicalTaskNameFromVsCodeTask -Label $label -Command $command -ReferenceTasks $ReferenceTasks
                    }

                    if (-not $tasks.ContainsKey($taskName)) {
                        $tasks[$taskName] = @{
                            Command     = $command
                            Description = if ($task.detail) { $task.detail } else { $null }
                            VsCodeLabel = $label
                        }
                    }
                }
            }
        }
    }
    catch {
        $errorMsg = "Failed to parse tasks.json: $_"
        Write-Warning $errorMsg
        # Return empty tasks rather than throwing to allow script to continue
    }
    
    return $tasks
}

Export-ModuleMember -Function Get-TasksFromFile, Get-TasksFromTaskfile, Get-TasksFromMakefile, Get-TasksFromPackageJson, Get-TasksFromJustfile, Get-TasksFromTasksJson, Get-ScriptPathFromTaskCommand, Get-TaskCommandSignature, Resolve-CanonicalTaskNameFromVsCodeTask, Convert-TasksJsonToCanonicalNames
