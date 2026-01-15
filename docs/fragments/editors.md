# editors.ps1

Editor and IDE integrations fragment.

## Overview

This fragment provides wrapper functions for code editors and IDEs, including VS Code (Visual Studio Code, VS Code Insiders, VS Codium), modern editors (Cursor, Lapce, Zed), Vim-based editors (Neovim, Vim, GoNeovim), classic editors (Emacs, Micro), and IDEs (Light Table, Theia IDE). Functions support launching editors, opening files and directories, and querying available editors.

## Functions

### Edit-WithVSCode

Opens files or directories in Visual Studio Code.

**Syntax:**

```powershell
Edit-WithVSCode [-Path <string>] [-NewWindow] [-Wait] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Optional): File or directory path to open. Defaults to current directory.
- `-NewWindow` (Switch): Open in a new window.
- `-Wait` (Switch): Wait for the editor to close before returning.

**Examples:**

```powershell
# Open current directory in VS Code
Edit-WithVSCode

# Open a directory in VS Code
Edit-WithVSCode -Path "C:\Projects\MyApp"

# Open a file in a new VS Code window
Edit-WithVSCode -Path "script.ps1" -NewWindow

# Open and wait for VS Code to close
Edit-WithVSCode -Path "script.ps1" -Wait
```

**Supported Tools:**

- `code-insiders` - VS Code Insiders (preferred)
- `code` - Visual Studio Code (fallback)
- `codium` - VS Codium (fallback)

**Notes:**

- Prefers `code-insiders`, falls back to `code`, then `codium`
- Creates process asynchronously (non-blocking) unless `-Wait` is used
- Returns nothing on success

---

### Edit-WithCursor

Opens files or directories in Cursor editor.

**Syntax:**

```powershell
Edit-WithCursor [-Path <string>] [-NewWindow] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Optional): File or directory path to open. Defaults to current directory.
- `-NewWindow` (Switch): Open in a new window.

**Examples:**

```powershell
# Open current directory in Cursor
Edit-WithCursor

# Open a directory in Cursor
Edit-WithCursor -Path "C:\Projects\MyApp"

# Open in a new window
Edit-WithCursor -Path "script.ps1" -NewWindow
```

**Supported Tools:**

- `cursor` - Cursor editor (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Edit-WithNeovim

Opens files in Neovim editor.

**Syntax:**

```powershell
Edit-WithNeovim [-Path <string>] [-UseGui] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Optional): File path to open. Defaults to current directory.
- `-UseGui` (Switch): Use GUI version (neovim-qt) if available.

**Examples:**

```powershell
# Open Neovim in current directory
Edit-WithNeovim

# Open a file in Neovim
Edit-WithNeovim -Path "script.ps1"

# Open in Neovim GUI
Edit-WithNeovim -Path "script.ps1" -UseGui
```

**Supported Tools:**

- `neovim-nightly` - Neovim nightly (preferred)
- `nvim` - Neovim (fallback)
- `neovim` - Neovim (fallback)
- `neovim-qt` - Neovim Qt GUI (when `-UseGui` specified)
- `nvim-qt` - Neovim Qt GUI (when `-UseGui` specified)

**Notes:**

- Prefers `neovim-nightly`, falls back to `nvim` or `neovim`
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-Emacs

Launches Emacs editor.

**Syntax:**

```powershell
Launch-Emacs [-Path <string>] [-NoWindow] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Optional): File path to open.
- `-NoWindow` (Switch): Start Emacs in daemon mode (no window).

**Examples:**

```powershell
# Launch Emacs
Launch-Emacs

# Open a file in Emacs
Launch-Emacs -Path "script.ps1"

# Start Emacs daemon
Launch-Emacs -NoWindow
```

**Supported Tools:**

- `emacs` - Emacs editor (required)

**Notes:**

- Creates process asynchronously (non-blocking) unless `-NoWindow` is used
- Returns nothing on success

---

### Launch-Lapce

Launches Lapce editor.

**Syntax:**

```powershell
Launch-Lapce [-Path <string>] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Optional): File or directory path to open. Defaults to current directory.

**Examples:**

```powershell
# Launch Lapce
Launch-Lapce

# Open a directory in Lapce
Launch-Lapce -Path "C:\Projects\MyApp"
```

**Supported Tools:**

- `lapce-nightly` - Lapce nightly (preferred)
- `lapce` - Lapce (fallback)

**Notes:**

- Prefers `lapce-nightly`, falls back to `lapce`
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-Zed

Launches Zed editor.

**Syntax:**

```powershell
Launch-Zed [-Path <string>] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Optional): File or directory path to open. Defaults to current directory.

**Examples:**

```powershell
# Launch Zed
Launch-Zed

# Open a directory in Zed
Launch-Zed -Path "C:\Projects\MyApp"
```

**Supported Tools:**

- `zed-nightly` - Zed nightly (preferred)
- `zed` - Zed (fallback)

**Notes:**

- Prefers `zed-nightly`, falls back to `zed`
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Get-EditorInfo

Gets information about available editors.

**Syntax:**

```powershell
Get-EditorInfo [<CommonParameters>]
```

**Examples:**

```powershell
# List all available editors
Get-EditorInfo

# Filter for specific editor
Get-EditorInfo | Where-Object { $_.Name -eq 'VS Code' }
```

**Output:**

Returns an array of objects with the following properties:

- `Name` (string): Editor display name
- `Command` (string): Command name used to launch the editor
- `Available` (bool): Whether the editor is available (always `true` in results)

**Supported Editors:**

- VS Code (`code-insiders`, `code`, `codium`)
- Cursor (`cursor`)
- Neovim (`neovim-nightly`, `nvim`, `neovim`)
- Neovim Qt (`neovim-qt`, `nvim-qt`)
- Vim (`vim-nightly`, `vim`)
- Emacs (`emacs`)
- Lapce (`lapce-nightly`, `lapce`)
- Zed (`zed-nightly`, `zed`)
- GoNeovim (`goneovim-nightly`, `goneovim`)
- Micro (`micro-nightly`, `micro`)
- Light Table (`lighttable`)
- Theia IDE (`theia-ide`)

**Notes:**

- Only returns editors that are actually installed and available
- Returns empty array if no editors are available
- Checks command availability using cached command detection

---

## Installation

Most editors can be installed via Scoop:

```powershell
# VS Code
scoop install vscode
scoop install vscode-insiders  # or vscodium

# Cursor
scoop install cursor

# Neovim
scoop install neovim-nightly
scoop install neovim-qt  # GUI version

# Emacs
scoop install emacs

# Lapce
scoop install lapce-nightly

# Zed
scoop install zed-nightly

# Other editors
scoop install vim-nightly
scoop install goneovim-nightly
scoop install micro-nightly
scoop install lighttable
scoop install theia-ide
```

## Graceful Degradation

All functions gracefully handle missing tools:

- Functions return `$null` when tools are not installed
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless `-ErrorAction Stop` is used)

## Performance

- Fragment load time: < 1000ms
- Function execution: < 100ms (for `Get-EditorInfo`)
- Idempotent: Safe to load multiple times

## See Also

- [terminal-enhanced.ps1](terminal-enhanced.md) - Terminal emulator functions
- [dev-tools-modules](../dev-tools-modules/) - Other development tool modules
