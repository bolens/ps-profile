# ===============================================
# game-dev.ps1
# Game development tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Game development tools fragment.

.DESCRIPTION
    Provides wrapper functions for game development tools:
    - 3D Modeling: Blockbench (3D model editor)
    - Tile Maps: Tiled (tile map editor)
    - Game Engines: Godot, Unity, Unreal Engine, RPG Maker

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides game development and asset creation capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'game-dev') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Launch-Blockbench - Launch Blockbench
    # ===============================================

    <#
    .SYNOPSIS
        Launches Blockbench 3D model editor.
    
    .DESCRIPTION
        Launches Blockbench, a 3D model editor for block-based models.
        Supports Minecraft, Bedrock, and other block-based game formats.
    
    .PARAMETER ProjectPath
        Optional path to project file to open.
    
    .EXAMPLE
        Launch-Blockbench
        
        Launches Blockbench.
    
    .EXAMPLE
        Launch-Blockbench -ProjectPath "model.bbmodel"
        
        Launches Blockbench and opens a project file.
    
    .OUTPUTS
        None.
    #>
    function Launch-Blockbench {
        [CmdletBinding()]
        param(
            [string]$ProjectPath
        )

        if (-not (Test-CachedCommand 'blockbench')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'blockbench' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'blockbench' -InstallHint $installHint
            }
            else {
                Write-Warning "blockbench is not installed. Install it with: scoop install blockbench"
            }
            return
        }

        $arguments = @()
        
        if ($ProjectPath) {
            if (-not (Test-Path -LiteralPath $ProjectPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Project file not found: $ProjectPath"),
                            'ProjectFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $ProjectPath
                        )) -OperationName 'game.blockbench.launch' -Context @{ project_path = $ProjectPath }
                }
                else {
                    Write-Error "Project file not found: $ProjectPath"
                }
                return
            }
            $arguments += $ProjectPath
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'game.blockbench.launch' -Context @{
                project_path = $ProjectPath
            } -ScriptBlock {
                Start-Process -FilePath 'blockbench' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'blockbench' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Blockbench: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-Tiled - Launch Tiled
    # ===============================================

    <#
    .SYNOPSIS
        Launches Tiled tile map editor.
    
    .DESCRIPTION
        Launches Tiled, a tile map editor for creating game levels and maps.
        Supports various tile map formats.
    
    .PARAMETER ProjectPath
        Optional path to map file to open.
    
    .EXAMPLE
        Launch-Tiled
        
        Launches Tiled.
    
    .EXAMPLE
        Launch-Tiled -ProjectPath "map.tmx"
        
        Launches Tiled and opens a map file.
    
    .OUTPUTS
        None.
    #>
    function Launch-Tiled {
        [CmdletBinding()]
        param(
            [string]$ProjectPath
        )

        if (-not (Test-CachedCommand 'tiled')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'tiled' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'tiled' -InstallHint $installHint
            }
            else {
                Write-Warning "tiled is not installed. Install it with: scoop install tiled"
            }
            return
        }

        $arguments = @()
        
        if ($ProjectPath) {
            if (-not (Test-Path -LiteralPath $ProjectPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Map file not found: $ProjectPath"),
                            'MapFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $ProjectPath
                        )) -OperationName 'game.tiled.launch' -Context @{ project_path = $ProjectPath }
                }
                else {
                    Write-Error "Map file not found: $ProjectPath"
                }
                return
            }
            $arguments += $ProjectPath
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'game.tiled.launch' -Context @{
                project_path = $ProjectPath
            } -ScriptBlock {
                Start-Process -FilePath 'tiled' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'tiled' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Tiled: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-Godot - Launch Godot
    # ===============================================

    <#
    .SYNOPSIS
        Launches Godot game engine.
    
    .DESCRIPTION
        Launches Godot game engine editor.
        Optionally opens a project.
    
    .PARAMETER ProjectPath
        Optional path to Godot project directory to open.
    
    .PARAMETER Headless
        Run in headless mode (no GUI).
    
    .EXAMPLE
        Launch-Godot
        
        Launches Godot editor.
    
    .EXAMPLE
        Launch-Godot -ProjectPath "C:\Projects\MyGame"
        
        Launches Godot and opens a project.
    
    .OUTPUTS
        None.
    #>
    function Launch-Godot {
        [CmdletBinding()]
        param(
            [string]$ProjectPath,
            
            [switch]$Headless
        )

        if (-not (Test-CachedCommand 'godot')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'godot' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'godot' -InstallHint $installHint
            }
            else {
                Write-Warning "godot is not installed. Install it with: scoop install godot"
            }
            return
        }

        $arguments = @()
        
        if ($Headless) {
            $arguments += '--headless'
        }
        
        if ($ProjectPath) {
            if (-not (Test-Path -LiteralPath $ProjectPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.DirectoryNotFoundException]::new("Project path not found: $ProjectPath"),
                            'ProjectPathNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $ProjectPath
                        )) -OperationName 'game.godot.launch' -Context @{ project_path = $ProjectPath }
                }
                else {
                    Write-Error "Project path not found: $ProjectPath"
                }
                return
            }
            $arguments += '--path', $ProjectPath
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'game.godot.launch' -Context @{
                project_path = $ProjectPath
                headless     = $Headless.IsPresent
            } -ScriptBlock {
                Start-Process -FilePath 'godot' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'godot' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Godot: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Build-GodotProject - Build Godot project
    # ===============================================

    <#
    .SYNOPSIS
        Builds a Godot project.
    
    .DESCRIPTION
        Builds a Godot project using the Godot command-line interface.
        Supports export presets and platform targets.
    
    .PARAMETER ProjectPath
        Path to Godot project directory.
    
    .PARAMETER ExportPreset
        Export preset name to use.
    
    .PARAMETER OutputPath
        Output directory for the build. Defaults to project directory.
    
    .PARAMETER Platform
        Target platform (e.g., 'windows', 'linux', 'macos', 'android', 'ios').
    
    .EXAMPLE
        Build-GodotProject -ProjectPath "C:\Projects\MyGame"
        
        Builds a Godot project.
    
    .EXAMPLE
        Build-GodotProject -ProjectPath "C:\Projects\MyGame" -ExportPreset "Windows Desktop"
        
        Builds a Godot project using a specific export preset.
    
    .OUTPUTS
        System.String. Path to the built project or output directory.
    #>
    function Build-GodotProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ProjectPath,
            
            [string]$ExportPreset,
            
            [string]$OutputPath,
            
            [string]$Platform
        )

        if (-not (Test-CachedCommand 'godot')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'godot' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'godot' -InstallHint $installHint
            }
            else {
                Write-Warning "godot is not installed. Install it with: scoop install godot"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $ProjectPath)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.DirectoryNotFoundException]::new("Project path not found: $ProjectPath"),
                        'ProjectPathNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $ProjectPath
                    )) -OperationName 'game.godot.build' -Context @{ project_path = $ProjectPath }
            }
            else {
                Write-Error "Project path not found: $ProjectPath"
            }
            return
        }

        $arguments = @('--headless', '--path', $ProjectPath)
        
        if ($ExportPreset) {
            $arguments += '--export', $ExportPreset
        }
        elseif ($Platform) {
            $arguments += '--export', $Platform
        }
        else {
            Write-Warning "No export preset or platform specified. Use -ExportPreset or -Platform."
            return
        }
        
        if ($OutputPath) {
            if (-not (Test-Path -LiteralPath $OutputPath)) {
                New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            }
            $arguments += $OutputPath
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'game.godot.build' -Context @{
                project_path  = $ProjectPath
                export_preset = $ExportPreset
                platform      = $Platform
                output_path   = $OutputPath
            } -ScriptBlock {
                $output = & godot $arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Godot build failed. Exit code: $LASTEXITCODE"
                }
                if ($OutputPath) {
                    return $OutputPath
                }
                return $ProjectPath
            }
        }
        else {
            try {
                $output = & godot $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    if ($OutputPath) {
                        return $OutputPath
                    }
                    return $ProjectPath
                }
                else {
                    Write-Error "Godot build failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to build Godot project: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-Unity - Launch Unity Hub/Editor
    # ===============================================

    <#
    .SYNOPSIS
        Launches Unity Hub or Unity Editor.
    
    .DESCRIPTION
        Launches Unity Hub (preferred) or Unity Editor.
        Unity Hub is the recommended way to manage Unity projects and versions.
    
    .PARAMETER ProjectPath
        Optional path to Unity project to open.
    
    .EXAMPLE
        Launch-Unity
        
        Launches Unity Hub.
    
    .EXAMPLE
        Launch-Unity -ProjectPath "C:\Projects\MyGame"
        
        Launches Unity and opens a project.
    
    .OUTPUTS
        None.
    #>
    function Launch-Unity {
        [CmdletBinding()]
        param(
            [string]$ProjectPath
        )

        # Prefer Unity Hub, fallback to Unity Editor
        $tool = $null
        if (Test-CachedCommand 'unity-hub') {
            $tool = 'unity-hub'
        }
        elseif (Test-CachedCommand 'unity') {
            $tool = 'unity'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'unity-hub' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'unity-hub' -InstallHint $installHint
            }
            else {
                Write-Warning "unity-hub or unity is not installed. Install it with: scoop install unity-hub"
            }
            return
        }

        $arguments = @()
        
        if ($ProjectPath) {
            if (-not (Test-Path -LiteralPath $ProjectPath)) {
                Write-Error "Project path not found: $ProjectPath"
                return
            }
            if ($tool -eq 'unity-hub') {
                $arguments += '--', $ProjectPath
            }
            else {
                $arguments += '-projectPath', $ProjectPath
            }
        }

        try {
            Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Unity: $($_.Exception.Message)"
        }
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Launch-Blockbench' -Body ${function:Launch-Blockbench}
        Set-AgentModeFunction -Name 'Launch-Tiled' -Body ${function:Launch-Tiled}
        Set-AgentModeFunction -Name 'Launch-Godot' -Body ${function:Launch-Godot}
        Set-AgentModeFunction -Name 'Build-GodotProject' -Body ${function:Build-GodotProject}
        Set-AgentModeFunction -Name 'Launch-Unity' -Body ${function:Launch-Unity}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'game-dev'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: game-dev" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load game-dev fragment: $($_.Exception.Message)"
        }
    }
}

