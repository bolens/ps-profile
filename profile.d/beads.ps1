# ===============================================
# beads.ps1
# Beads issue tracker (bd)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Beads issue tracker fragment for bd command.

.DESCRIPTION
    Provides wrapper function for Beads (bd), a lightweight memory system
    for coding agents using a graph-based issue tracker. Beads helps agents
    track dependencies, find ready work, and maintain long-term context.

.NOTES
    All functions gracefully degrade when bd is not installed.
    Use Get-ToolInstallHint for installation instructions.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'beads') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                # Get-RepoRoot expects scripts/ subdirectory, but we're in profile.d/
                # Fall back to manual path resolution
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Beads (bd) - Issue tracker for coding agents
    # ===============================================

    <#
    .SYNOPSIS
        Executes Beads (bd) commands.
    
    .DESCRIPTION
        Wrapper function for Beads CLI (bd) that executes commands for managing
        issues, dependencies, and ready work. Beads is a lightweight memory system
        for coding agents using a graph-based issue tracker.
    
    .PARAMETER Arguments
        Arguments to pass to bd command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-Beads init
        Initializes a new Beads database in the current repository.
    
    .EXAMPLE
        Invoke-Beads ready
        Shows issues that are ready to work on (no blockers).
    
    .EXAMPLE
        Invoke-Beads create "Fix bug" -p 1
        Creates a new issue with title "Fix bug" and priority 1.
    
    .OUTPUTS
        System.String. Output from bd execution.
    #>
    function Invoke-Beads {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'bd')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'bd' -ToolType 'generic'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'bd' -RepoRoot $repoRoot
            }
            else {
                "Install with: irm https://raw.githubusercontent.com/steveyegge/beads/main/install.ps1 | iex"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'bd' -InstallHint $installHint
            }
            else {
                Write-Warning "bd (Beads) not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'beads.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & bd $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & bd $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run bd: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Beads -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Beads' -Body ${function:Invoke-Beads}
    }
    if (-not (Get-Alias bd -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'bd' -Target 'Invoke-Beads'
        }
        else {
            Set-Alias -Name 'bd' -Value 'Invoke-Beads' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Helper Functions for Common Beads Operations
    # ===============================================

    <#
    .SYNOPSIS
        Initializes a Beads database in the current repository.
    
    .DESCRIPTION
        Initializes a new Beads issue tracker database in the current repository.
        This creates the .beads/ directory and sets up the database structure.
    
    .PARAMETER Contributor
        Initialize for contributor workflow (fork-based).
    
    .PARAMETER Team
        Initialize for team workflow (branch-based).
    
    .PARAMETER Branch
        Specify a branch name for protected branch workflows.
    
    .PARAMETER Quiet
        Run initialization non-interactively (for agents).
    
    .EXAMPLE
        Initialize-Beads
        Initializes Beads in the current repository.
    
    .EXAMPLE
        Initialize-Beads -Contributor
        Initializes Beads for contributor workflow.
    
    .OUTPUTS
        System.String. Output from bd init command.
    #>
    function Initialize-Beads {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [switch]$Contributor,
            [switch]$Team,
            [string]$Branch,
            [switch]$Quiet
        )

        $args = @('init')
        if ($Contributor) { $args += '--contributor' }
        if ($Team) { $args += '--team' }
        if ($Branch) { $args += '--branch', $Branch }
        if ($Quiet) { $args += '--quiet' }

        return Invoke-Beads -Arguments $args
    }

    <#
    .SYNOPSIS
        Gets issues that are ready to work on (no blockers).
    
    .DESCRIPTION
        Returns a list of issues that have no open blockers and are ready to be worked on.
    
    .PARAMETER Limit
        Maximum number of issues to return.
    
    .PARAMETER Priority
        Filter by priority level (0-4, where 0 is highest).
    
    .PARAMETER Assignee
        Filter by assignee.
    
    .PARAMETER Sort
        Sort order: priority, oldest, or hybrid (default).
    
    .PARAMETER Json
        Return output in JSON format.
    
    .EXAMPLE
        Get-BeadsReady
        Gets all ready issues.
    
    .EXAMPLE
        Get-BeadsReady -Limit 10 -Priority 1
        Gets top 10 P1 ready issues.
    
    .OUTPUTS
        System.String. Output from bd ready command.
    #>
    function Get-BeadsReady {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [int]$Limit,
            [int]$Priority,
            [string]$Assignee,
            [ValidateSet('priority', 'oldest', 'hybrid')]
            [string]$Sort,
            [switch]$Json
        )

        $args = @('ready')
        if ($Limit) { $args += '--limit', $Limit }
        if ($PSBoundParameters.ContainsKey('Priority')) { $args += '--priority', $Priority }
        if ($Assignee) { $args += '--assignee', $Assignee }
        if ($Sort) { $args += '--sort', $Sort }
        if ($Json) { $args += '--json' }

        return Invoke-Beads -Arguments $args
    }

    <#
    .SYNOPSIS
        Creates a new Beads issue.
    
    .DESCRIPTION
        Creates a new issue in the Beads tracker with the specified title and optional metadata.
    
    .PARAMETER Title
        Title of the issue.
    
    .PARAMETER Description
        Detailed description of the issue.
    
    .PARAMETER Priority
        Priority level (0-4, where 0 is highest, default is 2).
    
    .PARAMETER Type
        Issue type: bug, feature, task, epic, or chore (default: task).
    
    .PARAMETER Assignee
        Assign issue to a user.
    
    .PARAMETER Labels
        Comma-separated list of labels.
    
    .PARAMETER Json
        Return output in JSON format.
    
    .EXAMPLE
        New-BeadsIssue -Title "Fix bug" -Priority 1 -Type bug
        Creates a P1 bug issue.
    
    .EXAMPLE
        New-BeadsIssue -Title "Add feature" -Description "Detailed description" -Type feature
        Creates a feature issue with description.
    
    .OUTPUTS
        System.String. Output from bd create command.
    #>
    function New-BeadsIssue {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$Title,
            
            [string]$Description,
            
            [int]$Priority,
            
            [ValidateSet('bug', 'feature', 'task', 'epic', 'chore')]
            [string]$Type,
            
            [string]$Assignee,
            
            [string]$Labels,
            
            [switch]$Json
        )

        $args = @('create', $Title)
        if ($Description) { $args += '-d', $Description }
        if ($PSBoundParameters.ContainsKey('Priority')) { $args += '-p', $Priority }
        if ($Type) { $args += '-t', $Type }
        if ($Assignee) { $args += '-a', $Assignee }
        if ($Labels) { $args += '-l', $Labels }
        if ($Json) { $args += '--json' }

        return Invoke-Beads -Arguments $args
    }

    <#
    .SYNOPSIS
        Gets details of a specific Beads issue.
    
    .DESCRIPTION
        Retrieves full details of an issue by its ID.
    
    .PARAMETER IssueId
        The issue ID (e.g., bd-a1b2).
    
    .PARAMETER Json
        Return output in JSON format.
    
    .EXAMPLE
        Get-BeadsIssue -IssueId bd-a1b2
        Gets details for issue bd-a1b2.
    
    .OUTPUTS
        System.String. Output from bd show command.
    #>
    function Get-BeadsIssue {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$IssueId,
            
            [switch]$Json
        )

        $args = @('show', $IssueId)
        if ($Json) { $args += '--json' }

        return Invoke-Beads -Arguments $args
    }

    <#
    .SYNOPSIS
        Lists Beads issues with optional filters.
    
    .DESCRIPTION
        Lists issues matching the specified filters.
    
    .PARAMETER Status
        Filter by status (open, closed, in_progress).
    
    .PARAMETER Priority
        Filter by priority level (0-4).
    
    .PARAMETER Assignee
        Filter by assignee.
    
    .PARAMETER Labels
        Filter by labels (comma-separated, AND logic).
    
    .PARAMETER LabelsAny
        Filter by labels (comma-separated, OR logic).
    
    .PARAMETER Json
        Return output in JSON format.
    
    .EXAMPLE
        Get-BeadsIssues -Status open
        Lists all open issues.
    
    .EXAMPLE
        Get-BeadsIssues -Priority 1 -Labels "urgent,backend"
        Lists P1 issues with both urgent and backend labels.
    
    .OUTPUTS
        System.String. Output from bd list command.
    #>
    function Get-BeadsIssues {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$Status,
            
            [int]$Priority,
            
            [string]$Assignee,
            
            [string]$Labels,
            
            [string]$LabelsAny,
            
            [switch]$Json
        )

        $args = @('list')
        if ($Status) { $args += '--status', $Status }
        if ($PSBoundParameters.ContainsKey('Priority')) { $args += '--priority', $Priority }
        if ($Assignee) { $args += '--assignee', $Assignee }
        if ($Labels) { $args += '--label', $Labels }
        if ($LabelsAny) { $args += '--label-any', $LabelsAny }
        if ($Json) { $args += '--json' }

        return Invoke-Beads -Arguments $args
    }

    <#
    .SYNOPSIS
        Updates a Beads issue.
    
    .DESCRIPTION
        Updates an existing issue with new status, priority, assignee, or other fields.
    
    .PARAMETER IssueId
        The issue ID to update (e.g., bd-a1b2).
    
    .PARAMETER Status
        New status (open, closed, in_progress).
    
    .PARAMETER Priority
        New priority level (0-4).
    
    .PARAMETER Assignee
        New assignee.
    
    .PARAMETER Json
        Return output in JSON format.
    
    .EXAMPLE
        Update-BeadsIssue -IssueId bd-a1b2 -Status in_progress
        Updates issue status to in_progress.
    
    .EXAMPLE
        Update-BeadsIssue -IssueId bd-a1b2 -Priority 0
        Updates issue priority to P0.
    
    .OUTPUTS
        System.String. Output from bd update command.
    #>
    function Update-BeadsIssue {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$IssueId,
            
            [string]$Status,
            
            [int]$Priority,
            
            [string]$Assignee,
            
            [switch]$Json
        )

        $args = @('update', $IssueId)
        if ($Status) { $args += '--status', $Status }
        if ($PSBoundParameters.ContainsKey('Priority')) { $args += '--priority', $Priority }
        if ($Assignee) { $args += '--assignee', $Assignee }
        if ($Json) { $args += '--json' }

        return Invoke-Beads -Arguments $args
    }

    <#
    .SYNOPSIS
        Closes a Beads issue.
    
    .DESCRIPTION
        Closes one or more issues with an optional reason.
    
    .PARAMETER IssueId
        One or more issue IDs to close.
    
    .PARAMETER Reason
        Reason for closing the issue.
    
    .PARAMETER Json
        Return output in JSON format.
    
    .EXAMPLE
        Close-BeadsIssue -IssueId bd-a1b2 -Reason "Completed"
        Closes issue bd-a1b2 with reason "Completed".
    
    .EXAMPLE
        Close-BeadsIssue -IssueId bd-a1b2,bd-f14c -Reason "Fixed"
        Closes multiple issues.
    
    .OUTPUTS
        System.String. Output from bd close command.
    #>
    function Close-BeadsIssue {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [string[]]$IssueId,
            
            [string]$Reason,
            
            [switch]$Json
        )

        process {
            foreach ($id in $IssueId) {
                $args = @('close', $id)
                if ($Reason) { $args += '--reason', $Reason }
                if ($Json) { $args += '--json' }

                Invoke-Beads -Arguments $args
            }
        }
    }

    <#
    .SYNOPSIS
        Gets Beads statistics.
    
    .DESCRIPTION
        Returns statistics about issues in the database.
    
    .EXAMPLE
        Get-BeadsStats
        Gets issue statistics.
    
    .OUTPUTS
        System.String. Output from bd stats command.
    #>
    function Get-BeadsStats {
        [CmdletBinding()]
        [OutputType([string])]
        param()

        return Invoke-Beads -Arguments @('stats')
    }

    <#
    .SYNOPSIS
        Gets blocked issues.
    
    .DESCRIPTION
        Returns a list of issues that are blocked by other open issues.
    
    .EXAMPLE
        Get-BeadsBlocked
        Gets all blocked issues.
    
    .OUTPUTS
        System.String. Output from bd blocked command.
    #>
    function Get-BeadsBlocked {
        [CmdletBinding()]
        [OutputType([string])]
        param()

        return Invoke-Beads -Arguments @('blocked')
    }

    # Register helper functions
    if (-not (Test-Path Function:\Initialize-Beads -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Initialize-Beads' -Body ${function:Initialize-Beads}
    }
    if (-not (Test-Path Function:\Get-BeadsReady -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Get-BeadsReady' -Body ${function:Get-BeadsReady}
    }
    if (-not (Test-Path Function:\New-BeadsIssue -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'New-BeadsIssue' -Body ${function:New-BeadsIssue}
    }
    if (-not (Test-Path Function:\Get-BeadsIssue -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Get-BeadsIssue' -Body ${function:Get-BeadsIssue}
    }
    if (-not (Test-Path Function:\Get-BeadsIssues -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Get-BeadsIssues' -Body ${function:Get-BeadsIssues}
    }
    if (-not (Test-Path Function:\Update-BeadsIssue -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Update-BeadsIssue' -Body ${function:Update-BeadsIssue}
    }
    if (-not (Test-Path Function:\Close-BeadsIssue -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Close-BeadsIssue' -Body ${function:Close-BeadsIssue}
    }
    if (-not (Test-Path Function:\Get-BeadsStats -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Get-BeadsStats' -Body ${function:Get-BeadsStats}
    }
    if (-not (Test-Path Function:\Get-BeadsBlocked -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Get-BeadsBlocked' -Body ${function:Get-BeadsBlocked}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'beads'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'beads' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load beads fragment: $($_.Exception.Message)"
    }
}
