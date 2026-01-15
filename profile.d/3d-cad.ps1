# ===============================================
# 3d-cad.ps1
# 3D modeling and CAD tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    3D modeling and CAD tools fragment.

.DESCRIPTION
    Provides wrapper functions for 3D modeling and CAD tools:
    - 3D Modeling: Blender (3D modeling and animation)
    - CAD: FreeCAD (parametric CAD), OpenSCAD (programmatic CAD)
    - Mesh Processing: MeshLab, MeshMixer (mesh editing and processing)

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides 3D modeling, CAD, and mesh processing capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName '3d-cad') { return }
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
    # Launch-Blender - Launch Blender
    # ===============================================

    <#
    .SYNOPSIS
        Launches Blender 3D modeling and animation software.
    
    .DESCRIPTION
        Launches Blender, a 3D modeling, animation, and rendering software.
        Optionally opens a project file.
    
    .PARAMETER ProjectPath
        Optional path to Blender project file (.blend) to open.
    
    .PARAMETER Background
        Run in background mode (no GUI).
    
    .PARAMETER Script
        Python script to execute.
    
    .EXAMPLE
        Launch-Blender
        
        Launches Blender.
    
    .EXAMPLE
        Launch-Blender -ProjectPath "scene.blend"
        
        Launches Blender and opens a project file.
    
    .EXAMPLE
        Launch-Blender -Background -Script "render.py"
        
        Runs Blender in background mode with a Python script.
    
    .OUTPUTS
        None.
    #>
    function Launch-Blender {
        [CmdletBinding()]
        param(
            [string]$ProjectPath,
            
            [switch]$Background,
            
            [string]$Script
        )

        if (-not (Test-CachedCommand 'blender')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'blender' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'blender' -InstallHint $installHint
            }
            else {
                Write-Warning "blender is not installed. Install it with: scoop install blender"
            }
            return
        }

        $arguments = @()
        
        if ($Background) {
            $arguments += '--background'
        }
        
        if ($Script) {
            if (-not (Test-Path -LiteralPath $Script)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Script file not found: $Script"),
                            'ScriptFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $Script
                        )) -OperationName '3d.blender.launch' -Context @{ script = $Script }
                }
                else {
                    Write-Error "Script file not found: $Script"
                }
                return
            }
            $arguments += '--python', $Script
        }
        
        if ($ProjectPath) {
            if (-not (Test-Path -LiteralPath $ProjectPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Project file not found: $ProjectPath"),
                            'ProjectFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $ProjectPath
                        )) -OperationName '3d.blender.launch' -Context @{ project_path = $ProjectPath }
                }
                else {
                    Write-Error "Project file not found: $ProjectPath"
                }
                return
            }
            $arguments += $ProjectPath
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName '3d.blender.launch' -Context @{
                script       = $Script
                project_path = $ProjectPath
                background   = $Background.IsPresent
            } -ScriptBlock {
                Start-Process -FilePath 'blender' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'blender' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Blender: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-FreeCAD - Launch FreeCAD
    # ===============================================

    <#
    .SYNOPSIS
        Launches FreeCAD parametric CAD software.
    
    .DESCRIPTION
        Launches FreeCAD, a parametric 3D CAD modeler.
        Optionally opens a project file.
    
    .PARAMETER ProjectPath
        Optional path to FreeCAD project file (.FCStd) to open.
    
    .EXAMPLE
        Launch-FreeCAD
        
        Launches FreeCAD.
    
    .EXAMPLE
        Launch-FreeCAD -ProjectPath "model.FCStd"
        
        Launches FreeCAD and opens a project file.
    
    .OUTPUTS
        None.
    #>
    function Launch-FreeCAD {
        [CmdletBinding()]
        param(
            [string]$ProjectPath
        )

        if (-not (Test-CachedCommand 'freecad')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'freecad' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'freecad' -InstallHint $installHint
            }
            else {
                Write-Warning "freecad is not installed. Install it with: scoop install freecad"
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
                        )) -OperationName '3d.freecad.launch' -Context @{ project_path = $ProjectPath }
                }
                else {
                    Write-Error "Project file not found: $ProjectPath"
                }
                return
            }
            $arguments += $ProjectPath
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName '3d.freecad.launch' -Context @{
                project_path = $ProjectPath
            } -ScriptBlock {
                Start-Process -FilePath 'freecad' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'freecad' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch FreeCAD: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-OpenSCAD - Launch OpenSCAD
    # ===============================================

    <#
    .SYNOPSIS
        Launches OpenSCAD programmatic CAD software.
    
    .DESCRIPTION
        Launches OpenSCAD, a programmatic 3D CAD modeler.
        Optionally opens a script file.
    
    .PARAMETER ScriptPath
        Optional path to OpenSCAD script file (.scad) to open.
    
    .PARAMETER OutputPath
        Optional output path for rendered model.
    
    .PARAMETER Format
        Output format: 'stl', 'off', 'amf', '3mf', 'csg', 'dxf', 'svg', 'png', 'pdf'. Defaults to 'stl'.
    
    .EXAMPLE
        Launch-OpenSCAD
        
        Launches OpenSCAD.
    
    .EXAMPLE
        Launch-OpenSCAD -ScriptPath "model.scad"
        
        Launches OpenSCAD and opens a script file.
    
    .EXAMPLE
        Launch-OpenSCAD -ScriptPath "model.scad" -OutputPath "model.stl" -Format "stl"
        
        Launches OpenSCAD, opens a script, and renders to STL.
    
    .OUTPUTS
        System.String. Path to output file if rendered, otherwise nothing.
    #>
    function Launch-OpenSCAD {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$ScriptPath,
            
            [string]$OutputPath,
            
            [ValidateSet('stl', 'off', 'amf', '3mf', 'csg', 'dxf', 'svg', 'png', 'pdf')]
            [string]$Format = 'stl'
        )

        # Prefer openscad-dev, fallback to openscad
        $tool = $null
        if (Test-CachedCommand 'openscad-dev') {
            $tool = 'openscad-dev'
        }
        elseif (Test-CachedCommand 'openscad') {
            $tool = 'openscad'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'openscad-dev' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'openscad-dev' -InstallHint $installHint
            }
            else {
                Write-Warning "openscad-dev or openscad is not installed. Install it with: scoop install openscad-dev"
            }
            return
        }

        $arguments = @()
        
        if ($ScriptPath) {
            if (-not (Test-Path -LiteralPath $ScriptPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Script file not found: $ScriptPath"),
                            'ScriptFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $ScriptPath
                        )) -OperationName '3d.openscad.launch' -Context @{ script_path = $ScriptPath }
                }
                else {
                    Write-Error "Script file not found: $ScriptPath"
                }
                return
            }
            $arguments += $ScriptPath
        }
        
        if ($OutputPath) {
            $arguments += '-o', $OutputPath
        }
        else {
            # If script provided but no output, just open in GUI
            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Invoke-WithWideEvent -OperationName '3d.openscad.launch' -Context @{
                    script_path = $ScriptPath
                } -ScriptBlock {
                    Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
                } | Out-Null
                return
            }
            else {
                try {
                    Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
                    return
                }
                catch {
                    Write-Error "Failed to launch OpenSCAD: $($_.Exception.Message)"
                    return
                }
            }
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName '3d.openscad.render' -Context @{
                script_path = $ScriptPath
                output_path = $OutputPath
                format      = $Format
            } -ScriptBlock {
                $output = & $tool $arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "OpenSCAD rendering failed. Exit code: $LASTEXITCODE"
                }
                if (-not (Test-Path -LiteralPath $OutputPath)) {
                    throw "Output file was not created: $OutputPath"
                }
                Write-Host "Model rendered successfully: $OutputPath"
                return $OutputPath
            }
        }
        else {
            try {
                $output = & $tool $arguments 2>&1
                if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $OutputPath)) {
                    Write-Host "Model rendered successfully: $OutputPath"
                    return $OutputPath
                }
                else {
                    Write-Error "OpenSCAD rendering failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to render OpenSCAD model: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Convert-3DFormat - Convert 3D model formats
    # ===============================================

    <#
    .SYNOPSIS
        Converts 3D model between different formats using Blender.
    
    .DESCRIPTION
        Converts 3D model files between different formats using Blender's command-line interface.
        Supports many input and output formats (OBJ, STL, FBX, DAE, PLY, etc.).
    
    .PARAMETER InputFile
        Path to the input 3D model file.
    
    .PARAMETER OutputFile
        Path to the output 3D model file.
    
    .PARAMETER Format
        Output format. If not specified, inferred from OutputFile extension.
    
    .EXAMPLE
        Convert-3DFormat -InputFile "model.obj" -OutputFile "model.stl"
        
        Converts OBJ file to STL format.
    
    .EXAMPLE
        Convert-3DFormat -InputFile "model.fbx" -OutputFile "model.dae" -Format "dae"
        
        Converts FBX file to DAE format.
    
    .OUTPUTS
        System.String. Path to the output file.
    #>
    function Convert-3DFormat {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputFile,
            
            [Parameter(Mandatory = $true)]
            [string]$OutputFile,
            
            [string]$Format
        )

        if (-not (Test-CachedCommand 'blender')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'blender' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'blender' -InstallHint $installHint
            }
            else {
                Write-Warning "blender is not installed. Install it with: scoop install blender"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $InputFile)) {
            Write-Error "Input file not found: $InputFile"
            return
        }

        # Infer format from output file extension if not provided
        if (-not $Format) {
            $extension = [System.IO.Path]::GetExtension($OutputFile).TrimStart('.')
            $Format = $extension.ToLower()
        }

        # Create output directory if it doesn't exist
        $outputDir = Split-Path -Parent $OutputFile
        if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Create temporary Python script for Blender
        $tempScript = Join-Path $env:TEMP "blender_convert_$(New-Guid).py"
        $scriptContent = @"
import bpy
import sys

# Clear default scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Import input file
bpy.ops.wm.import_${Format}(filepath=r'$($InputFile.Replace('\', '\\'))')

# Export to output format
bpy.ops.wm.export_${Format}(filepath=r'$($OutputFile.Replace('\', '\\'))')
"@

        try {
            Set-Content -Path $tempScript -Value $scriptContent -ErrorAction Stop
            
            $arguments = @('--background', '--python', $tempScript)
            
            $output = & blender $arguments 2>&1
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $OutputFile)) {
                Write-Host "Model converted successfully: $OutputFile"
                return $OutputFile
            }
            else {
                Write-Error "3D format conversion failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to convert 3D model: $($_.Exception.Message)"
        }
        finally {
            if (Test-Path -LiteralPath $tempScript) {
                Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Render-3DScene - Render 3D scene with Blender
    # ===============================================

    <#
    .SYNOPSIS
        Renders a 3D scene using Blender.
    
    .DESCRIPTION
        Renders a 3D scene from a Blender project file using Blender's command-line interface.
        Supports various output formats and rendering engines.
    
    .PARAMETER ProjectPath
        Path to Blender project file (.blend).
    
    .PARAMETER OutputPath
        Path to output rendered image.
    
    .PARAMETER Frame
        Frame number to render. If not specified, renders current frame.
    
    .PARAMETER Engine
        Rendering engine: 'cycles', 'eevee', 'workbench'. Defaults to 'cycles'.
    
    .EXAMPLE
        Render-3DScene -ProjectPath "scene.blend" -OutputPath "render.png"
        
        Renders a Blender scene to PNG.
    
    .EXAMPLE
        Render-3DScene -ProjectPath "scene.blend" -OutputPath "render.png" -Frame 10 -Engine "eevee"
        
        Renders frame 10 using Eevee engine.
    
    .OUTPUTS
        System.String. Path to the rendered image.
    #>
    function Render-3DScene {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ProjectPath,
            
            [Parameter(Mandatory = $true)]
            [string]$OutputPath,
            
            [int]$Frame,
            
            [ValidateSet('cycles', 'eevee', 'workbench')]
            [string]$Engine = 'cycles'
        )

        if (-not (Test-CachedCommand 'blender')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'blender' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'blender' -InstallHint $installHint
            }
            else {
                Write-Warning "blender is not installed. Install it with: scoop install blender"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $ProjectPath)) {
            Write-Error "Project file not found: $ProjectPath"
            return
        }

        # Create output directory if it doesn't exist
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $arguments = @('--background', $ProjectPath, '--render-output', $OutputPath, '--engine', $Engine)
        
        if ($Frame) {
            $arguments += '--frame', $Frame.ToString()
        }
        else {
            $arguments += '--render-frame', '1'
        }

        try {
            $output = & blender $arguments 2>&1
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $OutputPath)) {
                Write-Host "Scene rendered successfully: $OutputPath"
                return $OutputPath
            }
            else {
                Write-Error "3D scene rendering failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to render 3D scene: $($_.Exception.Message)"
        }
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Launch-Blender' -Body ${function:Launch-Blender}
        Set-AgentModeFunction -Name 'Launch-FreeCAD' -Body ${function:Launch-FreeCAD}
        Set-AgentModeFunction -Name 'Launch-OpenSCAD' -Body ${function:Launch-OpenSCAD}
        Set-AgentModeFunction -Name 'Convert-3DFormat' -Body ${function:Convert-3DFormat}
        Set-AgentModeFunction -Name 'Render-3DScene' -Body ${function:Render-3DScene}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName '3d-cad'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: 3d-cad" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load 3d-cad fragment: $($_.Exception.Message)"
        }
    }
}

