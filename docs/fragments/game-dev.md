# game-dev.ps1

Game development tools fragment.

## Overview

This fragment provides wrapper functions for game development tools, including 3D modeling (Blockbench), tile map editing (Tiled), and game engines (Godot, Unity). Functions support launching editors, building projects, and managing game development workflows.

## Functions

### Launch-Blockbench

Launches Blockbench 3D model editor.

**Syntax:**

```powershell
Launch-Blockbench [-ProjectPath <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to project file to open.

**Examples:**

```powershell
# Launch Blockbench
Launch-Blockbench

# Launch Blockbench and open a project
Launch-Blockbench -ProjectPath "model.bbmodel"
```

**Supported Tools:**

- `blockbench` - 3D model editor (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-Tiled

Launches Tiled tile map editor.

**Syntax:**

```powershell
Launch-Tiled [-ProjectPath <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to map file to open.

**Examples:**

```powershell
# Launch Tiled
Launch-Tiled

# Launch Tiled and open a map
Launch-Tiled -ProjectPath "map.tmx"
```

**Supported Tools:**

- `tiled` - Tile map editor (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-Godot

Launches Godot game engine.

**Syntax:**

```powershell
Launch-Godot [-ProjectPath <string>] [-Headless] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to Godot project directory to open.
- `-Headless` (Switch): Run in headless mode (no GUI).

**Examples:**

```powershell
# Launch Godot editor
Launch-Godot

# Launch Godot and open a project
Launch-Godot -ProjectPath "C:\Projects\MyGame"

# Launch Godot in headless mode
Launch-Godot -ProjectPath "C:\Projects\MyGame" -Headless
```

**Supported Tools:**

- `godot` - Godot game engine (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Build-GodotProject

Builds a Godot project.

**Syntax:**

```powershell
Build-GodotProject -ProjectPath <string> [-ExportPreset <string>] [-OutputPath <string>] [-Platform <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Required): Path to Godot project directory.
- `-ExportPreset` (Optional): Export preset name to use.
- `-OutputPath` (Optional): Output directory for the build. Defaults to project directory.
- `-Platform` (Optional): Target platform (e.g., 'windows', 'linux', 'macos', 'android', 'ios').

**Examples:**

```powershell
# Build Godot project with export preset
Build-GodotProject -ProjectPath "C:\Projects\MyGame" -ExportPreset "Windows Desktop"

# Build for specific platform
Build-GodotProject -ProjectPath "C:\Projects\MyGame" -Platform "windows" -OutputPath "C:\Output"

# Build for Android
Build-GodotProject -ProjectPath "C:\Projects\MyGame" -Platform "android"
```

**Supported Tools:**

- `godot` - Godot game engine (required)

**Notes:**

- Requires either `-ExportPreset` or `-Platform` to be specified
- Creates output directory if it doesn't exist
- Returns path to output directory on success
- Returns project path if output path not specified

---

### Launch-Unity

Launches Unity Hub or Unity Editor.

**Syntax:**

```powershell
Launch-Unity [-ProjectPath <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to Unity project to open.

**Examples:**

```powershell
# Launch Unity Hub
Launch-Unity

# Launch Unity and open a project
Launch-Unity -ProjectPath "C:\Projects\MyGame"
```

**Supported Tools:**

- `unity-hub` - Unity Hub (preferred)
- `unity` - Unity Editor (fallback)

**Notes:**

- Prefers Unity Hub over Unity Editor when both are available
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

## Installation

Install game development tools using Scoop:

```powershell
# 3D Modeling
scoop install blockbench

# Tile Maps
scoop install tiled

# Game Engines
scoop install godot
scoop install unity-hub
```

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions return `$null` or empty when tools are unavailable
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless explicitly requested with `-ErrorAction Stop`)

## Testing

Comprehensive test coverage includes:

- Unit tests for editor functions (Launch-Blockbench, Launch-Tiled, Launch-Godot, Launch-Unity)
- Unit tests for build functions (Build-GodotProject)
- Integration tests for module loading and function registration
- Performance tests for load time and execution speed
- Graceful degradation tests for missing tools

Run tests:

```powershell
# Unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/game-dev.ps1

# Integration tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/integration/tools/game-dev.tests.ps1

# Performance tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/performance/game-dev-performance.tests.ps1
```

## Notes

- All editor launches are non-blocking (asynchronous)
- Build operations are blocking and return results
- Godot projects require export presets or platform specification for building
- Unity Hub is the recommended way to manage Unity projects and versions
