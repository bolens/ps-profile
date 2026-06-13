# Invoke-PnpmRun

## Synopsis

Runs npm scripts using pnpm.

## Description

Executes package.json scripts using pnpm instead of npm.

## Signature

```powershell
Invoke-PnpmRun
```

## Parameters

### -Script

package.json script name to execute.

### -Args

Additional arguments forwarded to the script command.


## Examples

### Example 1

```powershell
Invoke-PnpmRun -Script build -Args @('--watch')
```

## Aliases

This function has the following aliases:

- `pnrun` - Runs npm scripts using pnpm.


## Source

Defined in: ../profile.d/pnpm.ps1
