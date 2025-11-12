# Initialize-FragmentWarningSuppression

## Synopsis

Clears cached missing tool warnings.

## Description

Removes warning suppression entries so subsequent calls may emit warnings again. When no Tool parameter is provided, all cached warnings are cleared.

## Signature

```powershell
Initialize-FragmentWarningSuppression
```

## Parameters

### -Tool

Optional set of tool names whose warning entries should be cleared.


## Outputs

System.Boolean


## Examples

No examples provided.

## Source

Defined in: profile.d\00-bootstrap.ps1
