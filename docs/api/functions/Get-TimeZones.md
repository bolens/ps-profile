# Get-TimeZones

## Synopsis

Gets a list of available timezones.

## Description

Returns a list of all available timezones on the system.

## Signature

```powershell
Get-TimeZones
```

## Parameters

No parameters.

## Outputs

PSCustomObject[] Returns an array of timezone objects with Id, DisplayName, StandardName, DaylightName, and BaseUtcOffset properties.


## Examples

### Example 1

```powershell
Get-TimeZones
```

Lists all available timezones.

## Aliases

This function has the following aliases:

- `list-timezones` - Gets a list of available timezones.


## Source

Defined in: ../profile.d/conversion-modules/data/time/timezone.ps1
