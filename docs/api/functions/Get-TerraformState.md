# Get-TerraformState

## Synopsis

Queries Terraform state.

## Description

Queries Terraform state file to get information about managed resources. Supports various output formats and filtering options.

## Signature

```powershell
Get-TerraformState
```

## Parameters

### -ResourceAddress

Optional resource address to query. If not specified, lists all resources.

### -OutputFormat

Output format: json, raw. Defaults to raw.

### -StateFile

Optional path to state file. Defaults to terraform.tfstate in current directory.

### -Tool

Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).


## Outputs

System.String. State information in the specified format.


## Examples

### Example 1

`powershell
Get-TerraformState
        
        Lists all resources in the state file.
``

### Example 2

`powershell
Get-TerraformState -ResourceAddress "aws_instance.web" -OutputFormat "json"
        
        Gets specific resource information as JSON.
``

## Source

Defined in: ..\profile.d\iac-tools.ps1
