<#
scripts/utils/task-parity/modules/TaskGenerator.psm1

.SYNOPSIS
    Generates missing tasks in task runner files.

.DESCRIPTION
    Adds missing task definitions to task runner files in the appropriate format.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 5.0+
#>

function Add-MissingTasks {
    <#
    .SYNOPSIS
        Adds missing tasks to a task runner file.
    
    .DESCRIPTION
        Generates task definitions in the appropriate format and appends them to the file.
    
    .PARAMETER FilePath
        Path to the task file to update.
    
    .PARAMETER FileType
        Type of task file: 'taskfile', 'makefile', 'package', 'justfile', or 'tasksjson'.
    
    .PARAMETER MissingTaskNames
        Array of task names to add.
    
    .PARAMETER ReferenceTasks
        Hashtable of reference tasks (from another file) to use for command/description.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [ValidateSet('taskfile', 'makefile', 'package', 'justfile', 'tasksjson')]
        [string]$FileType,
        
        [Parameter(Mandatory)]
        [string[]]$MissingTaskNames,
        
        [Parameter(Mandatory)]
        [hashtable]$ReferenceTasks
    )
    
    if (-not $PSCmdlet.ShouldProcess($FilePath, "Add missing tasks: $($MissingTaskNames -join ', ')")) {
        return
    }
    
    $content = Get-Content -Path $FilePath -Raw
    $newTasks = @()
    
    foreach ($taskName in $MissingTaskNames) {
        if (-not $ReferenceTasks.ContainsKey($taskName)) {
            Write-Warning "Reference task '$taskName' not found, skipping"
            continue
        }
        
        $refTask = $ReferenceTasks[$taskName]
        $command = $refTask.Command
        $description = $refTask.Description
        
        switch ($FileType) {
            'taskfile' {
                $newTasks += Format-TaskfileTask -TaskName $taskName -Command $command -Description $description
            }
            'makefile' {
                $newTasks += Format-MakefileTask -TaskName $taskName -Command $command -Description $description
            }
            'package' {
                $newTasks += Format-PackageJsonTask -TaskName $taskName -Command $command
            }
            'justfile' {
                $newTasks += Format-JustfileTask -TaskName $taskName -Command $command -Description $description
            }
            'tasksjson' {
                # tasks.json is handled separately via Update-TasksJsonTasks
            }
        }
    }
    
    if ($newTasks.Count -eq 0 -and $FileType -ne 'tasksjson') {
        Write-Warning "No tasks to add"
        return
    }
    
    # Append new tasks to file
    $newContent = $newTasks -join "`n`n"
    
    # For package.json and tasks.json, we need to update JSON structure
    if ($FileType -eq 'package') {
        Update-PackageJsonTasks -FilePath $FilePath -NewTasks $MissingTaskNames -ReferenceTasks $ReferenceTasks
    }
    elseif ($FileType -eq 'tasksjson') {
        Update-TasksJsonTasks -FilePath $FilePath -NewTasks $MissingTaskNames -ReferenceTasks $ReferenceTasks
    }
    else {
        # For other files, append to end (before default task if exists)
        $lines = Get-Content -Path $FilePath
        $output = @()
        $inserted = $false
        
        foreach ($line in $lines) {
            # Insert before default task or at end
            if (-not $inserted -and ($line -match '^default:' -or ($line -match '^[a-zA-Z0-9_-]+:\s*$' -and $line.Trim() -eq 'default:'))) {
                $output += $newContent
                $inserted = $true
            }
            $output += $line
        }
        
        if (-not $inserted) {
            $output += ''
            $output += $newContent
        }
        
        Set-Content -Path $FilePath -Value $output -NoNewline
    }
}

function Format-TaskfileTask {
    <#
    .SYNOPSIS
        Formats a task for Taskfile.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$TaskName,
        
        [Parameter(Mandatory)]
        [string]$Command,
        
        [string]$Description = $null
    )
    
    $lines = @()
    $lines += "  $TaskName" + ':'
    
    if ($Description) {
        $lines += "    desc: $Description"
    }
    
    $lines += "    cmds:"
    
    # Split command by newlines and add each as a command
    $cmdLines = $Command -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($cmdLine in $cmdLines) {
        $trimmed = $cmdLine.Trim()
        # Convert argument placeholders
        $trimmed = $trimmed -replace '\{\{ARGS\}\}', '{{.CLI_ARGS}}'
        $trimmed = $trimmed -replace '\$\(ARGS\)', '{{.CLI_ARGS}}'
        $trimmed = $trimmed -replace '\{\{arguments\(\)\}\}', '{{.CLI_ARGS}}'
        $lines += "      - $trimmed"
    }
    
    return $lines -join "`n"
}

function Format-MakefileTask {
    <#
    .SYNOPSIS
        Formats a task for Makefile.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$TaskName,
        
        [Parameter(Mandatory)]
        [string]$Command,
        
        [string]$Description = $null
    )
    
    $lines = @()
    
    # Task definition with description
    if ($Description) {
        $lines += "$TaskName: ## $Description"
    }
    else {
        $lines += "$TaskName:"
    }
    
    # Split command by newlines and add each as a command (with tab)
    $cmdLines = $Command -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($cmdLine in $cmdLines) {
        $trimmed = $cmdLine.Trim()
        # Convert argument placeholders
        $trimmed = $trimmed -replace '\{\{ARGS\}\}', '$(ARGS)'
        $trimmed = $trimmed -replace '\{\{\.CLI_ARGS\}\}', '$(ARGS)'
        $trimmed = $trimmed -replace '\{\{arguments\(\)\}\}', '$(ARGS)'
        $lines += "`t$trimmed"
    }
    
    return $lines -join "`n"
}

function Format-PackageJsonTask {
    <#
    .SYNOPSIS
        Formats a task for package.json (returns just the command).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$TaskName,
        
        [Parameter(Mandatory)]
        [string]$Command
    )
    
    # Normalize command (package.json doesn't use argument placeholders typically)
    $normalized = $Command -replace '\{\{ARGS\}\}', '' -replace '\{\{\.CLI_ARGS\}\}', '' -replace '\{\{arguments\(\)\}\}', ''
    $normalized = $normalized.Trim()
    
    # Remove && echo statements that are common in package.json
    $normalized = $normalized -replace '\s*&&\s*echo\s+.*$', ''
    
    return $normalized
}

function Format-JustfileTask {
    <#
    .SYNOPSIS
        Formats a task for justfile.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$TaskName,
        
        [Parameter(Mandatory)]
        [string]$Command,
        
        [string]$Description = $null
    )
    
    $lines = @()
    
    # Description comment
    if ($Description) {
        $lines += "# $Description"
    }
    
    # Task definition
    $lines += "$TaskName`:"
    
    # Split command by newlines and add each as a command
    $cmdLines = $Command -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($cmdLine in $cmdLines) {
        $trimmed = $cmdLine.Trim()
        # Convert argument placeholders
        $trimmed = $trimmed -replace '\{\{ARGS\}\}', '{{arguments()}}'
        $trimmed = $trimmed -replace '\{\{\.CLI_ARGS\}\}', '{{arguments()}}'
        $trimmed = $trimmed -replace '\$\(ARGS\)', '{{arguments()}}'
        $lines += $trimmed
    }
    
    return $lines -join "`n"
}

function Update-PackageJsonTasks {
    <#
    .SYNOPSIS
        Updates package.json with new tasks (requires JSON manipulation).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string[]]$NewTasks,
        
        [Parameter(Mandatory)]
        [hashtable]$ReferenceTasks
    )
    
    try {
        $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        if (-not $json.scripts) {
            $json | Add-Member -MemberType NoteProperty -Name 'scripts' -Value @{} -Force
        }
        
        foreach ($taskName in $NewTasks) {
            if ($ReferenceTasks.ContainsKey($taskName)) {
                $refTask = $ReferenceTasks[$taskName]
                $command = Format-PackageJsonTask -TaskName $taskName -Command $refTask.Command
                $json.scripts | Add-Member -MemberType NoteProperty -Name $taskName -Value $command -Force
            }
        }
        
        # Convert back to JSON with proper formatting
        $jsonString = $json | ConvertTo-Json -Depth 10
        # Format JSON (basic indentation)
        $formatted = Format-JsonString -JsonString $jsonString
        Set-Content -Path $FilePath -Value $formatted -NoNewline
    }
    catch {
        throw "Failed to update package.json: $_"
    }
}

function Format-JsonString {
    <#
    .SYNOPSIS
        Formats a JSON string with consistent indentation.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$JsonString
    )
    
    # Use ConvertTo-Json with proper depth, then format
    try {
        $obj = $JsonString | ConvertFrom-Json
        return ($obj | ConvertTo-Json -Depth 10)
    }
    catch {
        # Fallback: return as-is
        return $JsonString
    }
}

function Update-TasksJsonTasks {
    <#
    .SYNOPSIS
        Updates tasks.json with new tasks (requires JSON manipulation).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string[]]$NewTasks,
        
        [Parameter(Mandatory)]
        [hashtable]$ReferenceTasks
    )
    
    try {
        $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        if (-not $json.tasks) {
            $json | Add-Member -MemberType NoteProperty -Name 'tasks' -Value @() -Force
        }
        
        foreach ($taskName in $NewTasks) {
            if ($ReferenceTasks.ContainsKey($taskName)) {
                $refTask = $ReferenceTasks[$taskName]
                $command = $refTask.Command
                $description = $refTask.Description
                
                # Parse command into command and args
                # Commands are typically: pwsh -NoProfile -File script.ps1 [args...]
                $cmdParts = $command -split '\s+'
                $taskCommand = $cmdParts[0]
                $taskArgs = @()
                
                # Extract arguments (skip the command itself)
                for ($i = 1; $i -lt $cmdParts.Count; $i++) {
                    $arg = $cmdParts[$i]
                    # Replace placeholders with VS Code variables
                    $arg = $arg -replace '\$\{workspaceFolder\}', '${workspaceFolder}'
                    # Convert {{ARGS}} to a placeholder that can be handled
                    if ($arg -match '\{\{ARGS\}\}' -or $arg -match '\{\{\.CLI_ARGS\}\}' -or $arg -match '\{\{arguments\(\)\}\}') {
                        # Skip argument placeholders for now (VS Code tasks don't have direct equivalents)
                        continue
                    }
                    $taskArgs += $arg
                }
                
                # Create task object
                $newTask = @{
                    label = $taskName
                    type = 'shell'
                    command = $taskCommand
                    args = $taskArgs
                    presentation = @{
                        reveal = 'always'
                    }
                    problemMatcher = @()
                }
                
                if ($description) {
                    $newTask.detail = $description
                }
                
                # Add to tasks array
                $json.tasks += $newTask
            }
        }
        
        # Convert back to JSON with proper formatting
        $jsonString = $json | ConvertTo-Json -Depth 10
        # Format JSON (basic indentation)
        $formatted = Format-JsonString -JsonString $jsonString
        Set-Content -Path $FilePath -Value $formatted -NoNewline
    }
    catch {
        throw "Failed to update tasks.json: $_"
    }
}

Export-ModuleMember -Function Add-MissingTasks, Format-TaskfileTask, Format-MakefileTask, Format-PackageJsonTask, Format-JustfileTask, Update-PackageJsonTasks, Update-TasksJsonTasks
