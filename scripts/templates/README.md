# Script Templates

This directory contains templates for creating new scripts in the PowerShell profile project.

## Available Templates

### utility-script-template.ps1

A template for creating utility scripts that perform various tasks. Includes:

- Standard parameter handling
- Modular library import pattern (ModuleImport.psm1 + Import-LibModule)
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
3. **Use shared utilities** - Import required modules from `scripts/lib/` and use their functions
4. **Handle errors properly** - Use Exit-WithCode for consistent exit codes
5. **Add examples** - Include usage examples in the help documentation
6. **Test thoroughly** - Ensure the script works in different scenarios

## Import Pattern

Scripts should import library modules using the modular import pattern (works from any script location):

```powershell
# Import ModuleImport first (bootstrap) - works from any scripts/ subdirectory
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import specific modules using Import-LibModule (handles path resolution automatically)
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking
```

**Available Library Modules:**

- `ModuleImport.psm1` - Module import helper (import this first)
- `ExitCodes.psm1` - Exit code constants (`Exit-WithCode`, `$EXIT_SUCCESS`, etc.)
- `PathResolution.psm1` - Path resolution (`Get-RepoRoot`)
- `Logging.psm1` - Logging utilities (`Write-ScriptMessage`)
- `Module.psm1` - Module management (`Ensure-ModuleAvailable`)
- `Command.psm1` - Command utilities (`Test-CommandAvailable`)
- `FileSystem.psm1` - File system operations (`Ensure-DirectoryExists`)
- And many more (see `scripts/lib/` directory)
