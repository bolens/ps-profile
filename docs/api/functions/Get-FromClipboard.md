# Get-FromClipboard

## Synopsis

Pastes content from the clipboard.

## Description

Retrieves content from the clipboard. Uses Get-Clipboard on Windows/pwsh, wl-paste (Wayland), xclip/xsel (X11), or pbpaste (macOS) as available.

## Signature

```powershell
Get-FromClipboard
```

## Parameters

No parameters.

## Outputs

System.String


## Examples

### Example 1

```powershell
Get-FromClipboard
```

## Aliases

This function has the following aliases:

- `pb` - Pastes content from the clipboard.


## Source

Defined in: ../profile.d/clipboard.ps1
