# Open-Item

## Synopsis

Opens files or URLs using the system's default application.

## Description

Opens the specified file or URL using the appropriate system command. On Windows, uses Start-Process. On Linux/macOS, uses xdg-open or open.

## Signature

```powershell
Open-Item
```

## Parameters

### -p

File path, directory, or URL to open with the system default handler.


## Examples

### Example 1

`powershell
Open-Item ./README.md
``

### Example 2

`powershell
Open-Item https://example.com
.PARAMETER p
    File path, directory, or URL to open with the system default handler.
``

## Aliases

This function has the following aliases:

- `open` - Opens files or URLs using the system's default application.


## Source

Defined in: ../profile.d/open.ps1
