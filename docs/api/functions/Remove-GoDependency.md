# Remove-GoDependency

## Synopsis

Removes Go module dependencies.

## Description

Removes packages from go.mod using go mod edit -droprequire.

## Signature

```powershell
Remove-GoDependency
```

## Parameters

### -Packages

Package paths to remove (e.g., github.com/user/package).


## Examples

### Example 1

`powershell
Remove-GoDependency github.com/gin-gonic/gin
    Removes gin from dependencies.
``

## Source

Defined in: ..\profile.d\go.ps1
