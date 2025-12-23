# iac-tools.ps1

Infrastructure as Code tools fragment.

## Overview

The `iac-tools.ps1` fragment provides enhanced wrapper functions for Infrastructure as Code tools, building on the existing `terraform.ps1` and `ansible.ps1` modules:

- **Terragrunt**: Terraform wrapper for DRY configurations
- **OpenTofu**: Open-source Terraform fork
- **Pulumi**: Infrastructure as code with multiple programming languages
- **Enhanced Terraform Operations**: State queries, planning, and applying with tool selection

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration
- `terraform.ps1` - Base Terraform support (optional)
- `ansible.ps1` - Ansible support (optional)

## Functions

### Invoke-Terragrunt

Executes Terragrunt commands.

**Syntax:**
```powershell
Invoke-Terragrunt [<Arguments>] [<CommonParameters>]
```

**Parameters:**
- `Arguments` - Arguments to pass to terragrunt.

**Examples:**
```powershell
# Run terragrunt plan
Invoke-Terragrunt plan

# Apply Terragrunt changes automatically
Invoke-Terragrunt apply -auto-approve
```

**Installation:**
```powershell
scoop install terragrunt
```

---

### Invoke-OpenTofu

Executes OpenTofu commands.

**Syntax:**
```powershell
Invoke-OpenTofu [<Arguments>] [<CommonParameters>]
```

**Parameters:**
- `Arguments` - Arguments to pass to opentofu.

**Examples:**
```powershell
# Initialize OpenTofu working directory
Invoke-OpenTofu init

# Create an OpenTofu execution plan
Invoke-OpenTofu plan
```

**Installation:**
```powershell
scoop install opentofu
```

---

### Plan-Infrastructure

Plans infrastructure changes.

**Syntax:**
```powershell
Plan-Infrastructure [-Tool <string>] [-OutputFile <string>] [<Arguments>] [<CommonParameters>]
```

**Parameters:**
- `Tool` - Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).
- `OutputFile` - Optional file to save the plan to.
- `Arguments` - Additional arguments to pass to the plan command.

**Examples:**
```powershell
# Create a plan using the default tool (Terraform)
Plan-Infrastructure

# Create a plan using OpenTofu and save to plan.out
Plan-Infrastructure -OutputFile "plan.out" -Tool "opentofu"

# Create a plan with additional arguments
Plan-Infrastructure -Arguments "-detailed-exitcode"
```

**Installation:**
```powershell
# Terraform (preferred)
scoop install terraform

# OpenTofu (fallback)
scoop install opentofu
```

---

### Apply-Infrastructure

Applies infrastructure changes.

**Syntax:**
```powershell
Apply-Infrastructure [-Tool <string>] [-PlanFile <string>] [-AutoApprove] [<Arguments>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**
- `Tool` - Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).
- `PlanFile` - Optional plan file to apply.
- `AutoApprove` - Automatically approve the apply without prompting.
- `Arguments` - Additional arguments to pass to the apply command.

**Examples:**
```powershell
# Apply infrastructure changes using the default tool
Apply-Infrastructure

# Apply a specific plan file automatically
Apply-Infrastructure -PlanFile "plan.out" -AutoApprove

# Apply with auto-approve
Apply-Infrastructure -AutoApprove
```

**Installation:**
```powershell
# Terraform (preferred)
scoop install terraform

# OpenTofu (fallback)
scoop install opentofu
```

---

### Get-TerraformState

Queries Terraform state.

**Syntax:**
```powershell
Get-TerraformState [-ResourceAddress <string>] [-OutputFormat <string>] [-StateFile <string>] [-Tool <string>] [<CommonParameters>]
```

**Parameters:**
- `ResourceAddress` - Optional resource address to query. If not specified, lists all resources.
- `OutputFormat` - Output format: json, raw. Defaults to raw.
- `StateFile` - Optional path to state file. Defaults to terraform.tfstate in current directory.
- `Tool` - Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).

**Examples:**
```powershell
# List all resources in the state file
Get-TerraformState

# Get specific resource information as JSON
Get-TerraformState -ResourceAddress "aws_instance.web" -OutputFormat "json"

# Query state from a specific state file
Get-TerraformState -StateFile "custom.tfstate"
```

**Installation:**
```powershell
# Terraform (preferred)
scoop install terraform

# OpenTofu (fallback)
scoop install opentofu
```

---

### Invoke-Pulumi

Executes Pulumi commands.

**Syntax:**
```powershell
Invoke-Pulumi [<Arguments>] [<CommonParameters>]
```

**Parameters:**
- `Arguments` - Arguments to pass to pulumi.

**Examples:**
```powershell
# Preview Pulumi changes
Invoke-Pulumi preview

# Apply Pulumi changes automatically
Invoke-Pulumi up --yes
```

**Installation:**
```powershell
scoop install pulumi
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)
- Plan-Infrastructure and Apply-Infrastructure prefer Terraform but fallback to OpenTofu

## Installation

Install required tools using Scoop:

```powershell
# Install all IAC tools
scoop install terraform terragrunt opentofu pulumi

# Or install individually
scoop install terraform   # Infrastructure tool (preferred)
scoop install terragrunt  # Terraform wrapper
scoop install opentofu    # Terraform fork (fallback)
scoop install pulumi      # Infrastructure as code with multiple languages
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:
```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/iac-tools.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/iac-tools.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/iac-tools-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- This module enhances existing terraform.ps1 and ansible.ps1 modules
- Plan-Infrastructure and Apply-Infrastructure prefer Terraform but fallback to OpenTofu when Terraform is not available
- Get-TerraformState supports both Terraform and OpenTofu state files
- Terragrunt is a thin wrapper around Terraform for DRY configurations
- OpenTofu is an open-source fork of Terraform with the same interface
- Pulumi supports multiple programming languages (TypeScript, Python, Go, C#, etc.)

