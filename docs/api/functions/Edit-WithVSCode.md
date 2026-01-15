# Edit-WithVSCode

## Synopsis

Opens files or directories in Visual Studio Code.

## Description

Opens files or directories in VS Code. Prefers vscode-insiders, falls back to vscode or vscodium. Optionally opens in a new window.

## Signature

```powershell
Edit-WithVSCode
```

## Parameters

### -Path

File or directory path to open. Defaults to current directory.

### -NewWindow

Open in a new window.

### -Wait

Wait for the editor to close before returning.


## Outputs

None.


## Examples

### Example 1

`powershell
Edit-WithVSCode
        
        Opens current directory in VS Code.
``

### Example 2

`powershell
Edit-WithVSCode -Path "C:\Projects\MyApp"
        
        Opens a directory in VS Code.
``

### Example 3

`powershell
Edit-WithVSCode -Path "script.ps1" -NewWindow
        
        Opens a file in a new VS Code window.
``

## Source

Defined in: ..\profile.d\editors.ps1
