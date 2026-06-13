# Enable-ScoopCompletion

## Synopsis

Instead, it creates an Enable-ScoopCompletion function that can be called on-demand to enable

## Description

<# # Tier: essential # Dependencies: bootstrap, env <# <# # scoop-completion.ps1 Idempotent lazy-loading setup for Scoop tab completion. This fragment discovers the Scoop completion module path but does not import it immediately. Instead, it creates an Enable-ScoopCompletion function that can be called on-demand to enable completion features. This lazy loading approach keeps profile startup fast.

## Signature

```powershell
Enable-ScoopCompletion
```

## Parameters

No parameters.

## Examples

No examples provided.

## Source

Defined in: ../profile.d/scoop-completion.ps1
