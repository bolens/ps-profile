# Invoke-Supabase

## Synopsis

Executes Supabase CLI commands.

## Description

Wrapper function for Supabase CLI that executes Supabase commands. Supabase is an open-source Firebase alternative with PostgreSQL database.

## Signature

```powershell
Invoke-Supabase
```

## Parameters

### -Arguments

Arguments to pass to supabase command. Can be used multiple times or as an array.


## Outputs

System.String. Output from Supabase CLI execution.


## Examples

### Example 1

```powershell
Invoke-Supabase status
```

Checks Supabase local development status.

### Example 2

```powershell
Invoke-Supabase start
```

Starts local Supabase development environment.

### Example 3

```powershell
Invoke-Supabase stop
```

Stops local Supabase development environment.

## Aliases

This function has the following aliases:

- `supabase` - Executes Supabase CLI commands.


## Source

Defined in: ../profile.d/database-clients.ps1
