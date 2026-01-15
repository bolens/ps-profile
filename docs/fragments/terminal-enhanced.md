# terminal-enhanced.ps1

Enhanced terminal tools fragment.

## Overview

This fragment provides wrapper functions for terminal emulators and multiplexers, including Alacritty, Kitty, WezTerm, Tabby, and tmux. Functions support launching terminal emulators, managing tmux sessions, and querying available terminal tools.

## Functions

### Launch-Alacritty

Launches Alacritty terminal emulator.

**Syntax:**

```powershell
Launch-Alacritty [-Command <string>] [-WorkingDirectory <string>] [<CommonParameters>]
```

**Parameters:**

- `-Command` (Optional): Command to execute in the new terminal.
- `-WorkingDirectory` (Optional): Working directory for the new terminal.

**Examples:**

```powershell
# Launch Alacritty terminal
Launch-Alacritty

# Launch Alacritty and execute a command
Launch-Alacritty -Command "git status"

# Launch Alacritty in a specific directory
Launch-Alacritty -WorkingDirectory "C:\Projects"
```

**Supported Tools:**

- `alacritty` - Terminal emulator (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-Kitty

Launches Kitty terminal emulator.

**Syntax:**

```powershell
Launch-Kitty [-Command <string>] [-WorkingDirectory <string>] [<CommonParameters>]
```

**Parameters:**

- `-Command` (Optional): Command to execute in the new terminal.
- `-WorkingDirectory` (Optional): Working directory for the new terminal.

**Examples:**

```powershell
# Launch Kitty terminal
Launch-Kitty

# Launch Kitty and execute a command
Launch-Kitty -Command "npm start"
```

**Supported Tools:**

- `kitty` - Terminal emulator (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-WezTerm

Launches WezTerm terminal emulator.

**Syntax:**

```powershell
Launch-WezTerm [-Command <string>] [-WorkingDirectory <string>] [<CommonParameters>]
```

**Parameters:**

- `-Command` (Optional): Command to execute in the new terminal.
- `-WorkingDirectory` (Optional): Working directory for the new terminal.

**Examples:**

```powershell
# Launch WezTerm terminal
Launch-WezTerm

# Launch WezTerm and execute a command
Launch-WezTerm -Command "docker ps"
```

**Supported Tools:**

- `wezterm-nightly` - WezTerm nightly build (preferred)
- `wezterm` - WezTerm stable build (fallback)

**Notes:**

- Prefers wezterm-nightly over wezterm when both are available
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Launch-Tabby

Launches Tabby terminal emulator.

**Syntax:**

```powershell
Launch-Tabby [-Command <string>] [-WorkingDirectory <string>] [<CommonParameters>]
```

**Parameters:**

- `-Command` (Optional): Command to execute in the new terminal.
- `-WorkingDirectory` (Optional): Working directory for the new terminal.

**Examples:**

```powershell
# Launch Tabby terminal
Launch-Tabby

# Launch Tabby and execute a command
Launch-Tabby -Command "npm run dev"
```

**Supported Tools:**

- `tabby` - Terminal emulator (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Start-Tmux

Starts a tmux terminal multiplexer session.

**Syntax:**

```powershell
Start-Tmux [-SessionName <string>] [-Command <string>] [-Attach] [<CommonParameters>]
```

**Parameters:**

- `-SessionName` (Optional): Name for the tmux session. If not provided, creates a new session.
- `-Command` (Optional): Command to execute in the new session.
- `-Attach` (Switch): Attach to existing session if it exists, otherwise create new one.

**Examples:**

```powershell
# Start a new tmux session
Start-Tmux

# Start a named tmux session
Start-Tmux -SessionName "dev"

# Start a named session and execute a command
Start-Tmux -SessionName "dev" -Command "npm start"

# Attach to existing session or create new one
Start-Tmux -SessionName "dev" -Attach
```

**Supported Tools:**

- `tmux` - Terminal multiplexer (required)

**Notes:**

- Creates session in detached mode, then attaches
- Returns session name on success
- If session exists and `-Attach` is specified, attaches to existing session

---

### Get-TerminalInfo

Gets information about available terminal emulators.

**Syntax:**

```powershell
Get-TerminalInfo [<CommonParameters>]
```

**Examples:**

```powershell
# List all available terminal emulators
Get-TerminalInfo

# Filter by name
Get-TerminalInfo | Where-Object { $_.Name -eq 'Alacritty' }
```

**Outputs:**

Returns an array of objects with the following properties:

- `Name` - Terminal name (e.g., "Alacritty", "Kitty", "WezTerm")
- `Command` - Command name used to launch the terminal
- `Available` - Boolean indicating if the terminal is available

**Notes:**

- Checks for installed terminals using `Test-CachedCommand`
- Prefers development/nightly builds over stable builds
- Returns empty array if no terminals are available

---

## Installation

Install terminal emulators using Scoop:

```powershell
# Terminal Emulators
scoop install alacritty
scoop install kitty
scoop install wezterm-nightly
scoop install tabby

# Terminal Multiplexers
scoop install tmux
scoop install screen
```

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions return `$null` or empty when tools are unavailable
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless explicitly requested with `-ErrorAction Stop`)

## Testing

Comprehensive test coverage includes:

- Unit tests for terminal emulator functions (Launch-Alacritty, Launch-Kitty, Launch-WezTerm, Launch-Tabby)
- Unit tests for multiplexer functions (Start-Tmux, Get-TerminalInfo)
- Integration tests for module loading and function registration
- Performance tests for load time and execution speed
- Graceful degradation tests for missing tools

Run tests:

```powershell
# Unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/terminal-enhanced.ps1

# Integration tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/integration/tools/terminal-enhanced.tests.ps1

# Performance tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/performance/terminal-enhanced-performance.tests.ps1
```

## Notes

- All terminal launches are non-blocking (asynchronous)
- Terminal emulators support command execution and working directory specification
- tmux sessions are created in detached mode and then attached
- Get-TerminalInfo provides quick overview of available terminal tools
