# View-WithBat

## Synopsis

Views files with syntax highlighting using bat.

## Description

Enhanced wrapper for bat (cat clone) with syntax highlighting, line numbers, Git integration, and paging support.

## Signature

```powershell
View-WithBat
```

## Parameters

### -Path

File path to view. Can be a single file or multiple files.

### -Language

Explicitly set syntax highlighting language (e.g., "powershell", "markdown").

### -LineNumbers

Show line numbers (default: true).

### -Plain

Disable syntax highlighting (plain text mode).

### -Pager

Use pager for output (default: true if output is long).

### -Wrap

Wrap long lines (default: false).

### -Theme

Color theme to use (e.g., "dark", "light", "GitHub").


## Outputs

System.String. File contents with syntax highlighting.


## Examples

### Example 1

```powershell
View-WithBat -Path "script.ps1"
```

Views PowerShell script with syntax highlighting.

### Example 2

```powershell
View-WithBat -Path "README.md" -Language "markdown" -Wrap
```

Views markdown file with wrapping enabled.

### Example 3

```powershell
View-WithBat -Path "file.txt" -Plain
```

Views file as plain text without highlighting.

## Aliases

This function has the following aliases:

- `vbat` - Views files with syntax highlighting using bat.


## Source

Defined in: ../profile.d/cli-modules/modern-cli.ps1
