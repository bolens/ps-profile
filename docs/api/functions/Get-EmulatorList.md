# Get-EmulatorList

## Synopsis

Lists available emulators on the system.

## Description

Checks for installed emulators and returns a list of available ones. Groups by console/system.

## Signature

```powershell
Get-EmulatorList
```

## Parameters

No parameters.

## Outputs

System.Object[]. Array of emulator information objects.


## Examples

### Example 1

`powershell
Get-EmulatorList
        
        Lists all available emulators.
``

## Source

Defined in: ..\profile.d\game-emulators.ps1
