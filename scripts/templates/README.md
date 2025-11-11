# Script Templates

This directory contains templates for creating new scripts in the PowerShell profile project.

## Available Templates

### utility-script-template.ps1

A template for creating utility scripts that perform various tasks. Includes:

- Standard parameter handling
- Common.psm1 import pattern
- Repository root resolution
- Error handling with standardized exit codes
- Consistent logging

**Usage:**

```powershell
Copy-Item scripts/templates/utility-script-template.ps1 scripts/utils/my-new-script.ps1
# Edit the template to add your functionality
```

### check-script-template.ps1

A template for creating validation/check scripts. Includes:

- Standard validation script structure
- Exit code handling (0 = pass, 1 = validation failure)
- Path parameter with default to repo root
- Issue tracking and reporting

**Usage:**

```powershell
Copy-Item scripts/templates/check-script-template.ps1 scripts/checks/my-new-check.ps1
# Edit the template to add your validation logic
```

## Template Guidelines

When creating scripts from templates:

1. **Update the synopsis and description** - Clearly describe what the script does
2. **Add appropriate parameters** - Follow PowerShell parameter naming conventions
3. **Use shared utilities** - Import Common.psm1 and use its functions
4. **Handle errors properly** - Use Exit-WithCode for consistent exit codes
5. **Add examples** - Include usage examples in the help documentation
6. **Test thoroughly** - Ensure the script works in different scenarios

## Import Pattern by Script Location

Scripts should import Common.psm1 using the appropriate pattern for their location:

- **scripts/utils/ subdirectories** (e.g., code-quality/, metrics/): `Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'`
- **scripts/checks/**: `Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'`
- **scripts/git/**: `$scriptsDir = Split-Path -Parent $PSScriptRoot; Join-Path $scriptsDir 'lib' 'Common.psm1'`
- **scripts/lib/**: `Join-Path $PSScriptRoot 'Common.psm1'` (same directory)
