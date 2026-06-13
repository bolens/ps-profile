# Copy-ToClipboard

## Synopsis

Copies input to the clipboard.

## Description

Copies text or objects to the clipboard. Uses Set-Clipboard on Windows/pwsh, wl-copy (Wayland), xclip/xsel (X11), or pbcopy (macOS) as available.

## Signature

```powershell
Copy-ToClipboard
```

## Parameters

### -InputObject

The object(s) to copy. Accepts pipeline input.


## Examples

### Example 1

```powershell
"hello" | Copy-ToClipboard
```

### Example 2

```powershell
Get-Content file.txt | Copy-ToClipboard
```

## Aliases

This function has the following aliases:

- `cb` - Copies input to the clipboard.


## Source

Defined in: ../profile.d/clipboard.ps1
