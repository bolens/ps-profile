# Invoke-Supabase

## Synopsis

Executes Supabase CLI commands.

## Description

Wrapper function for Supabase CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Supabase
```

## Parameters

### -Arguments

Arguments to pass to supabase.


## Examples

### Example 1

`powershell
Invoke-Supabase status
``

### Example 2

`powershell
Invoke-Supabase start
``

## Aliases

This function has the following aliases:

- `supabase` - Executes Supabase CLI commands.


## Source

Defined in: ..\profile.d\database.ps1
