# 3d-cad.ps1

3D modeling and CAD tools fragment.

## Overview

This fragment provides wrapper functions for 3D modeling and CAD tools, including Blender (3D modeling and animation), FreeCAD (parametric CAD), OpenSCAD (programmatic CAD), and mesh processing tools. Functions support launching editors, converting 3D formats, and rendering 3D scenes.

## Functions

### Launch-Blender

Launches Blender 3D modeling and animation software.

**Syntax:**

```powershell
Launch-Blender [-ProjectPath <string>] [-Background] [-Script <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to Blender project file (.blend) to open.
- `-Background` (Switch): Run in background mode (no GUI).
- `-Script` (Optional): Python script to execute.

**Examples:**

```powershell
# Launch Blender
Launch-Blender

# Launch Blender and open a project
Launch-Blender -ProjectPath "scene.blend"

# Run Blender in background with a script
Launch-Blender -Background -Script "render.py"
```

**Supported Tools:**

- `blender` - 3D modeling and animation software (required)

**Notes:**

- Creates process asynchronously (non-blocking) unless `-Background` is used
- Returns nothing on success

---

### Launch-FreeCAD

Launches FreeCAD parametric CAD software.

**Syntax:**

```powershell
Launch-FreeCAD [-ProjectPath <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to FreeCAD project file (.FCStd) to open.

**Examples:**

```powershell
# Launch FreeCAD
Launch-FreeCAD

# Launch FreeCAD and open a project
Launch-FreeCAD -ProjectPath "model.FCStd"
```

**Supported Tools:**

- `freecad` - Parametric CAD software (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-OpenSCAD

Launches OpenSCAD programmatic CAD software.

**Syntax:**

```powershell
Launch-OpenSCAD [-ScriptPath <string>] [-OutputPath <string>] [-Format <string>] [<CommonParameters>]
```

**Parameters:**

- `-ScriptPath` (Optional): Path to OpenSCAD script file (.scad) to open.
- `-OutputPath` (Optional): Output path for rendered model.
- `-Format` (Optional): Output format: 'stl', 'off', 'amf', '3mf', 'csg', 'dxf', 'svg', 'png', 'pdf'. Defaults to 'stl'.

**Examples:**

```powershell
# Launch OpenSCAD
Launch-OpenSCAD

# Launch OpenSCAD and open a script
Launch-OpenSCAD -ScriptPath "model.scad"

# Render OpenSCAD script to STL
Launch-OpenSCAD -ScriptPath "model.scad" -OutputPath "model.stl" -Format "stl"
```

**Supported Tools:**

- `openscad-dev` - OpenSCAD development build (preferred)
- `openscad` - OpenSCAD stable build (fallback)

**Notes:**

- Prefers openscad-dev over openscad when both are available
- If `-OutputPath` is provided, renders the model (blocking operation)
- If `-OutputPath` is not provided, opens in GUI (non-blocking)
- Returns path to output file if rendered, otherwise nothing

---

### Convert-3DFormat

Converts 3D model between different formats using Blender.

**Syntax:**

```powershell
Convert-3DFormat -InputFile <string> -OutputFile <string> [-Format <string>] [<CommonParameters>]
```

**Parameters:**

- `-InputFile` (Required): Path to the input 3D model file.
- `-OutputFile` (Required): Path to the output 3D model file.
- `-Format` (Optional): Output format. If not specified, inferred from OutputFile extension.

**Examples:**

```powershell
# Convert OBJ to STL
Convert-3DFormat -InputFile "model.obj" -OutputFile "model.stl"

# Convert FBX to DAE
Convert-3DFormat -InputFile "model.fbx" -OutputFile "model.dae" -Format "dae"
```

**Supported Tools:**

- `blender` - 3D modeling software (required)

**Notes:**

- Uses Blender's command-line interface for format conversion
- Creates temporary Python script for conversion
- Supports many input and output formats (OBJ, STL, FBX, DAE, PLY, etc.)
- Returns path to output file on success

---

### Render-3DScene

Renders a 3D scene using Blender.

**Syntax:**

```powershell
Render-3DScene -ProjectPath <string> -OutputPath <string> [-Frame <int>] [-Engine <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Required): Path to Blender project file (.blend).
- `-OutputPath` (Required): Path to output rendered image.
- `-Frame` (Optional): Frame number to render. If not specified, renders current frame.
- `-Engine` (Optional): Rendering engine: 'cycles', 'eevee', 'workbench'. Defaults to 'cycles'.

**Examples:**

```powershell
# Render Blender scene to PNG
Render-3DScene -ProjectPath "scene.blend" -OutputPath "render.png"

# Render specific frame with Eevee engine
Render-3DScene -ProjectPath "scene.blend" -OutputPath "render.png" -Frame 10 -Engine "eevee"
```

**Supported Tools:**

- `blender` - 3D modeling software (required)

**Notes:**

- Uses Blender's command-line interface for rendering
- Runs in background mode (no GUI)
- Supports multiple rendering engines (Cycles, Eevee, Workbench)
- Returns path to rendered image on success

---

## Installation

Install 3D/CAD tools using Scoop:

```powershell
# 3D Modeling
scoop install blender

# CAD Software
scoop install freecad
scoop install openscad-dev

# Mesh Processing (optional)
scoop install meshlab
scoop install meshmixer
```

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions return `$null` or empty when tools are unavailable
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless explicitly requested with `-ErrorAction Stop`)

## Testing

Comprehensive test coverage includes:

- Unit tests for editor functions (Launch-Blender, Launch-FreeCAD, Launch-OpenSCAD)
- Unit tests for operation functions (Convert-3DFormat, Render-3DScene)
- Integration tests for module loading and function registration
- Performance tests for load time and execution speed
- Graceful degradation tests for missing tools

Run tests:

```powershell
# Unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/3d-cad.ps1

# Integration tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/integration/tools/3d-cad.tests.ps1

# Performance tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/performance/3d-cad-performance.tests.ps1
```

## Notes

- Editor launches are non-blocking (asynchronous) unless background mode is specified
- Format conversion and rendering operations are blocking and return results
- Blender is used for format conversion and rendering operations
- OpenSCAD supports both GUI mode and command-line rendering
- All operations require the respective tools to be installed
