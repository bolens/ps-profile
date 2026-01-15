# Edit-WithCursor

## Synopsis

Opens files or directories in Cursor editor.

## Description

Opens files or directories in Cursor, an AI-powered code editor. Optionally opens in a new window.

## Signature

```powershell
Edit-WithCursor
```

## Parameters

### -Path

File or directory path to open. Defaults to current directory.

### -NewWindow

Open in a new window.


## Outputs

None.


## Examples

### Example 1

`powershell
Edit-WithCursor
        
        Opens current directory in Cursor.
``

### Example 2

`powershell
Edit-WithCursor -Path "C:\Projects\MyApp"
        
        Opens a directory in Cursor.
``

## Source

Defined in: ..\profile.d\editors.ps1
