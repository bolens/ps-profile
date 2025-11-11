# Save-FragmentConfig

## Synopsis

Converts PSCustomObject or Hashtable to Hashtable recursively.

## Description

Recursively converts PSCustomObject instances to Hashtable structures. Handles nested objects and arrays. If input is already a Hashtable, returns it unchanged. Accepts PSCustomObject, Hashtable, or any object that can be converted.

## Signature

```powershell
Save-FragmentConfig
```

## Parameters

### -InputObject

The object to convert. Accepts PSCustomObject, Hashtable, or any object. Expected types: [PSCustomObject], [hashtable], or any object (null returns empty hashtable). Type: [object] (accepts multiple types for flexibility).


## Outputs

Hashtable. The converted hashtable structure. .EXAMPLE $obj = [PSCustomObject]@{ Name = 'Test'; Nested = [PSCustomObject]@{ Value = 123 } } $hash = ConvertTo-Hashtable -InputObject $obj


## Examples

### Example 1

`powershell
$obj = [PSCustomObject]@{ Name = 'Test'; Nested = [PSCustomObject]@{ Value = 123 } }
        $hash = ConvertTo-Hashtable -InputObject $obj
``

## Source

Defined in: profile.d\00-bootstrap.ps1
