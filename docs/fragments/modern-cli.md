# modern-cli.ps1

Modern CLI tools fragment.

## Overview

This fragment provides PowerShell functions and aliases for modern command-line tools, including bat (syntax-highlighted cat), fd (fast find), zoxide (smart cd), ripgrep (fast grep), and other modern CLI utilities. The fragment includes both basic tool wrappers and enhanced wrapper functions with additional features and better integration.

## Functions

### Basic Tool Wrappers

The fragment provides basic wrappers for the following tools using `Register-ToolWrapper`:

- `bat` - Syntax-highlighted cat clone
- `fd` - Fast find alternative
- `http` - Command-line HTTP client (httpie)
- `zoxide` - Smart cd command
- `delta` - Syntax-highlighting pager for git
- `tldr` - Simplified man pages
- `procs` - Modern replacement for ps
- `dust` - More intuitive du command

These basic wrappers check for tool availability and display installation hints when tools are missing.

### Find-WithFd

Finds files and directories using fd with enhanced options.

**Syntax:**

```powershell
Find-WithFd [-Pattern] <string> [-Path <string>] [-Type <string>] [-Extension <string>] [-CaseSensitive] [-Hidden] [-FollowSymlinks] [<CommonParameters>]
```

**Parameters:**

- `-Pattern` (Mandatory): Search pattern (file name or path pattern).
- `-Path` (Optional): Starting directory for search. Defaults to current directory.
- `-Type` (Optional): File type filter: f (files), d (directories), l (symlinks).
- `-Extension` (Optional): File extension filter (e.g., "ps1", "md").
- `-CaseSensitive` (Switch): Enable case-sensitive search (default: false).
- `-Hidden` (Switch): Include hidden files and directories (default: false).
- `-FollowSymlinks` (Switch): Follow symbolic links (default: false).

**Examples:**

```powershell
# Find all files containing "test" in the name
Find-WithFd -Pattern "test"

# Find all PowerShell script files
Find-WithFd -Pattern "*.ps1" -Type f -Extension "ps1"

# Find config files including hidden ones
Find-WithFd -Pattern "config" -Path "C:\Users" -Hidden

# Case-sensitive search
Find-WithFd -Pattern "Test" -CaseSensitive
```

**Supported Tools:**

- `fd` - Fast find alternative (required)

**Aliases:**

- `ffd` - Short alias for Find-WithFd

**Notes:**

- Returns array of matching file/directory paths
- Returns empty array if fd is not available
- Case-insensitive search by default
- Excludes hidden files by default

---

### Grep-WithRipgrep

Searches text using ripgrep with enhanced options.

**Syntax:**

```powershell
Grep-WithRipgrep [-Pattern] <string> [-Path <string>] [-FileType <string>] [-CaseSensitive] [-Context <int>] [-OnlyMatching] [-FilesWithMatches] [-Hidden] [<CommonParameters>]
```

**Parameters:**

- `-Pattern` (Mandatory): Text pattern to search for (regex supported).
- `-Path` (Optional): Directory or file to search in. Defaults to current directory.
- `-FileType` (Optional): File type filter (e.g., "ps1", "md", "json"). Uses ripgrep type filters.
- `-CaseSensitive` (Switch): Enable case-sensitive search (default: false).
- `-Context` (Optional): Number of context lines to show before and after matches.
- `-OnlyMatching` (Switch): Show only matching text, not full lines.
- `-FilesWithMatches` (Switch): Show only file names that contain matches.
- `-Hidden` (Switch): Search hidden files and directories (default: false).

**Examples:**

```powershell
# Search for "function" in all files
Grep-WithRipgrep -Pattern "function"

# Search for "error" in PowerShell files with context
Grep-WithRipgrep -Pattern "error" -FileType "ps1" -Context 3

# List only files containing "TODO"
Grep-WithRipgrep -Pattern "TODO" -FilesWithMatches

# Case-sensitive search
Grep-WithRipgrep -Pattern "Error" -CaseSensitive
```

**Supported Tools:**

- `rg` - ripgrep (required)

**Aliases:**

- `grg` - Short alias for Grep-WithRipgrep

**Notes:**

- Returns search results from ripgrep
- Returns empty string if rg is not available
- Exit code 1 (no matches) is treated as valid
- Case-insensitive search by default
- Always includes line numbers

---

### Navigate-WithZoxide

Navigates to directories using zoxide's smart matching.

**Syntax:**

```powershell
Navigate-WithZoxide [[-Query] <string>] [-Interactive] [-Add] [-Remove <string>] [-QueryAll] [<CommonParameters>]
```

**Parameters:**

- `-Query` (Optional): Directory name or path to navigate to. Can be partial match.
- `-Interactive` (Switch): Use interactive mode to select from multiple matches.
- `-Add` (Switch): Add current directory to zoxide database.
- `-Remove` (Optional): Remove directory from zoxide database.
- `-QueryAll` (Switch): Query all directories in database.

**Examples:**

```powershell
# Navigate to most frequently used directory matching "Documents"
Navigate-WithZoxide -Query "Documents"

# Interactive navigation
Navigate-WithZoxide -Query "PowerShell" -Interactive

# Add current directory to database
Navigate-WithZoxide -Add

# List all directories in database
Navigate-WithZoxide -QueryAll

# Remove directory from database
Navigate-WithZoxide -Remove "C:\OldProject"
```

**Supported Tools:**

- `zoxide` - Smart cd command (required)

**Aliases:**

- `z` - Short alias for Navigate-WithZoxide

**Notes:**

- Changes current directory when navigation succeeds
- Returns path navigated to, or null if navigation failed
- Returns null if zoxide is not available
- Uses frequency-based ranking for directory matching

---

### View-WithBat

Views files with syntax highlighting using bat.

**Syntax:**

```powershell
View-WithBat [-Path] <string[]> [-Language <string>] [-LineNumbers] [-Plain] [-Pager] [-Wrap] [-Theme <string>] [<CommonParameters>]
```

**Parameters:**

- `-Path` (Mandatory): File path to view. Can be a single file or multiple files.
- `-Language` (Optional): Explicitly set syntax highlighting language (e.g., "powershell", "markdown").
- `-LineNumbers` (Switch): Show line numbers (default: true).
- `-Plain` (Switch): Disable syntax highlighting (plain text mode).
- `-Pager` (Switch): Use pager for output (default: false).
- `-Wrap` (Switch): Wrap long lines (default: false).
- `-Theme` (Optional): Color theme to use (e.g., "dark", "light", "GitHub").

**Examples:**

```powershell
# View PowerShell script with syntax highlighting
View-WithBat -Path "script.ps1"

# View markdown file with wrapping
View-WithBat -Path "README.md" -Language "markdown" -Wrap

# View file as plain text
View-WithBat -Path "file.txt" -Plain

# View multiple files
View-WithBat -Path "file1.ps1", "file2.ps1"

# View with custom theme
View-WithBat -Path "script.ps1" -Theme "GitHub"
```

**Supported Tools:**

- `bat` - Syntax-highlighted cat clone (required)

**Aliases:**

- `vbat` - Short alias for View-WithBat

**Notes:**

- Returns file contents with syntax highlighting
- Returns nothing if bat is not available
- Warns if file does not exist
- Line numbers enabled by default
- Paging disabled by default

---

## Aliases

The fragment provides the following aliases for enhanced functions:

- `ffd` → `Find-WithFd`
- `grg` → `Grep-WithRipgrep`
- `z` → `Navigate-WithZoxide`
- `vbat` → `View-WithBat`

## Installation

Install the required tools using Scoop:

```powershell
# Install all modern CLI tools
scoop install fd ripgrep zoxide bat

# Or install individually
scoop install fd      # Fast find
scoop install ripgrep # Fast grep
scoop install zoxide  # Smart cd
scoop install bat     # Syntax-highlighted cat
```

## Notes

- All functions check for tool availability using `Test-CachedCommand`
- Functions gracefully degrade when tools are missing (display warnings)
- Enhanced functions provide better integration than basic wrappers
- Basic wrappers are still available for direct tool access
- Enhanced functions support additional options and features
