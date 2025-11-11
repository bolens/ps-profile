# Register-LazyFunction

## Synopsis

Registers a lazy-loading function that initializes on first use.

## Description

Creates a function stub that calls an initializer function on first invocation, then delegates to the actual function implementation. This pattern allows expensive initialization to be deferred until the function is actually used. The stub is replaced with the actual function after first initialization.

## Signature

```powershell
Register-LazyFunction
```

## Parameters

### -Name

The name of the function to register.

### -Initializer

A scriptblock that performs initialization (e.g., calls Ensure-* functions). This is executed once on first function call. The initializer should create the actual function with the same name.

### -Alias

Optional alias name to create for the function.


## Examples

### Example 1

`powershell
# Define the actual function in an Ensure-* helper
        function Ensure-GitHelper {
            if ($script:__GitHelpersInitialized) { return }
            Set-AgentModeFunction -Name 'Invoke-GitClone' -Body { git clone @args }
        }

        # Register lazy stub
        Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { Ensure-GitHelper } -Alias 'gcl'

        # First call initializes and invokes, subsequent calls use actual function
        Invoke-GitClone https://github.com/user/repo.git
``

### Example 2

`powershell
# Register multiple lazy functions with the same initializer
        Register-LazyFunction -Name 'Save-GitStash' -Initializer { Ensure-GitHelper } -Alias 'gsta'
        Register-LazyFunction -Name 'Restore-GitStash' -Initializer { Ensure-GitHelper } -Alias 'gstp'
``

## Notes

This helper reduces code duplication when registering multiple lazy-loading functions. The initializer is only called once per function, even if multiple functions share the same initializer.


## Source

Defined in: profile.d\00-bootstrap.ps1
