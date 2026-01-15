# Update-CocoaPodsDependencies

## Synopsis

Updates CocoaPods dependencies.

## Description

Updates dependencies to latest versions allowed by Podfile.

## Signature

```powershell
Update-CocoaPodsDependencies
```

## Parameters

### -Pods

Specific pod names to update (optional, updates all if omitted).


## Examples

### Example 1

`powershell
Update-CocoaPodsDependencies
        Updates all dependencies.
``

### Example 2

`powershell
Update-CocoaPodsDependencies Alamofire
        Updates specific pod.
``

## Aliases

This function has the following aliases:

- `podupdate` - Updates CocoaPods dependencies.


## Source

Defined in: ..\profile.d\cocoapods.ps1
