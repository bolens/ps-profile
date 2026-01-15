# Module Documentation Template

This document provides a standardized template for documenting PowerShell profile modules and fragments.

## Base Module Template

```powershell
# ===============================================
# ModuleName.ps1
# Brief description of the module
# ===============================================

<#
.SYNOPSIS
    Brief one-line description of the module.

.DESCRIPTION
    Detailed description of the module's purpose and functionality.
    Provides helper functions that [specific modules] can use or extend.
    
    Common Patterns:
    1. Pattern description one
    2. Pattern description two
    3. Pattern description three
    4. Pattern description four
    5. Pattern description five

.NOTES
    This is a base module. [Specific modules] (module1.ps1, module2.ps1)
    should use these functions or extend them with [domain]-specific logic.
#>
```

## Fragment Module Template

```powershell
# ===============================================
# fragment-name.ps1
# Brief description of the fragment
# ===============================================
# Tier: [core|standard|optional]
# Dependencies: [dependency1, dependency2]
# Environment: [development, production, etc.]

<#
.SYNOPSIS
    Brief one-line description of the fragment.

.DESCRIPTION
    Detailed description of what the fragment provides:
    - Feature one
    - Feature two
    - Feature three
    - Additional features

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use [standardized pattern] for [specific use case].
#>
```

## Function Documentation Template

```powershell
<#
.SYNOPSIS
    Brief one-line description of what the function does.

.DESCRIPTION
    Detailed description of the function's behavior, including:
    - What it does
    - When to use it
    - Important considerations
    - Edge cases handled

.PARAMETER ParameterName
    Description of the parameter, including:
    - What it represents
    - Valid values or constraints
    - Default behavior if optional

.PARAMETER AnotherParameter
    Description of another parameter.

.EXAMPLE
    Function-Name -ParameterName 'value'
    
    Brief description of what this example demonstrates.

.EXAMPLE
    Function-Name -ParameterName 'value' -AnotherParameter 'other'
    
    Another example showing different usage.

.OUTPUTS
    System.Type. Description of what the function returns.
#>
```

## Documentation Standards

### Required Sections

1. **Header Comment Block**: File name and brief description
2. **.SYNOPSIS**: One-line summary (required for all functions)
3. **.DESCRIPTION**: Detailed explanation
4. **.NOTES**: Additional context, dependencies, or important information

### Optional Sections

- **.PARAMETER**: For each parameter (required if function has parameters)
- **.EXAMPLE**: Usage examples (at least one recommended)
- **.OUTPUTS**: Return type and description
- **.LINK**: Related documentation or resources

### Formatting Guidelines

1. **Consistency**: Use consistent formatting across all modules
2. **Clarity**: Write clear, concise descriptions
3. **Completeness**: Document all public functions and parameters
4. **Examples**: Include practical examples where helpful
5. **Patterns**: For base modules, list common patterns in DESCRIPTION

### Base Module Specific Guidelines

- Always include "Common Patterns" list in DESCRIPTION
- Always include .NOTES explaining it's a base module
- List which specific modules should use or extend the base

### Fragment Module Specific Guidelines

- Include tier, dependencies, and environment in header comments
- Document graceful degradation behavior
- Note which standardized patterns are used

## Validation

Use PSScriptAnalyzer to validate documentation:

```powershell
Invoke-ScriptAnalyzer -Path module.ps1 -Settings PSScriptAnalyzerSettings.psd1
```

The settings file enforces:
- All functions must have .SYNOPSIS
- All parameters must have .PARAMETER documentation
- Comment-based help is required

## Examples

See the following files for good examples:

- `profile.d/bootstrap/CloudProviderBase.ps1` - Base module example
- `profile.d/bootstrap/LanguageBase.ps1` - Base module example
- `profile.d/bootstrap/PromptBase.ps1` - Base module example
- `profile.d/git-enhanced.ps1` - Fragment module example
- `profile.d/iac-tools.ps1` - Fragment module example
