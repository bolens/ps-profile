# Register-DeprecatedFunction

## Synopsis

Registers a deprecated function or alias with a deprecation warning.

## Description

Creates a wrapper function that displays a deprecation warning when called, then forwards the call to the new function. Useful for maintaining backward compatibility while encouraging migration to new APIs.

## Signature

```powershell
Register-DeprecatedFunction
```

## Parameters

### -OldName

The name of the deprecated function or alias.

### -NewName

The name of the replacement function or alias.

### -RemovalVersion

Optional. The version when the deprecated function will be removed.

### -Message

Optional. Custom deprecation message. If not provided, a default message is used.


## Examples

### Example 1

`powershell
Register-DeprecatedFunction -OldName 'Old-Function' -NewName 'New-Function' -RemovalVersion '2.0.0'
``

### Example 2

`powershell
Register-DeprecatedFunction -OldName 'old-alias' -NewName 'new-alias' -Message 'This alias is deprecated'
``

## Source

Defined in: profile.d\00-bootstrap.ps1
