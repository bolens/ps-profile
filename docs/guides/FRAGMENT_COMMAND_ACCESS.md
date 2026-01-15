# Fragment Command Access

**Status**: ✅ Complete  
**Version**: 1.0.0

## Overview

The Fragment Command Access system enables running commands from PowerShell profile fragments without requiring the full profile to be loaded or manually referencing fragment files. This provides seamless command execution, on-demand fragment loading, and standalone script wrappers.

## Features

### 1. Command Registry

All fragment commands (functions and aliases) are automatically registered in a global registry that maps commands to their source fragments. This enables:

- Fast command-to-fragment lookups
- Command discovery and introspection
- On-demand fragment loading

### 2. On-Demand Fragment Loading

Fragments can be loaded automatically when their commands are called, even if the profile hasn't fully loaded. This enables:

- Commands work in `-NoProfile` sessions
- Lazy loading of fragments (only load when needed)
- Automatic dependency resolution

### 3. Command Dispatcher

A transparent command dispatcher hooks into PowerShell's `CommandNotFoundAction` to automatically detect and load fragments when unknown commands are invoked. This provides:

- Seamless command execution (no manual fragment loading)
- Transparent integration with existing code
- Chains with existing CommandNotFound handlers

### 4. Standalone Script Wrappers

Executable PowerShell script wrappers can be generated for all fragment commands, enabling:

- Commands can be called from any shell
- Works in non-PowerShell environments (via wrappers)
- Enables scripting and automation

## Usage

### Automatic Command Loading

By default, the command dispatcher is enabled and will automatically load fragments when commands are called:

```powershell
# Command dispatcher automatically loads the fragment
Invoke-Aws --version
```

### Manual Fragment Loading

You can manually load a fragment for a specific command:

```powershell
# Load fragment for a command
Load-FragmentForCommand -CommandName 'Invoke-Aws'

# Or load a fragment directly
Load-Fragment -FragmentName 'aws'
```

### Command Registry Queries

Query the command registry to discover commands:

```powershell
# Check if a command is registered
Test-CommandInRegistry -CommandName 'Invoke-Aws'

# Get fragment for a command
Get-FragmentForCommand -CommandName 'Invoke-Aws'

# Get all commands for a fragment
Get-CommandsForFragment -FragmentName 'aws'

# Get detailed registry info
Get-CommandRegistryInfo -CommandName 'Invoke-Aws'

# Get registry statistics
Get-CommandRegistryStats
```

### Generating Standalone Wrappers

Generate executable wrappers for fragment commands:

```powershell
# Generate wrappers for all commands
task generate-command-wrappers
# or
pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1

# Generate wrapper for a specific command
pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1 -CommandName 'Invoke-Aws'

# Preview what would be generated
pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1 -DryRun

# Regenerate all wrappers (overwrite existing)
pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1 -Force
```

After generating wrappers, add `scripts/bin/` to your PATH:

```powershell
# Windows (PowerShell)
$env:Path += ";$PSScriptRoot\scripts\bin"

# Or permanently (requires admin):
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$PSScriptRoot\scripts\bin", "User")
```

## Configuration

### Environment Variables

- `PS_PROFILE_AUTO_LOAD_FRAGMENTS` - Enable/disable auto-loading (default: `1`/enabled)
  - Set to `0` or `false` to disable automatic fragment loading
- `PS_PROFILE_AUTO_LOAD_TIMEOUT` - Timeout in seconds for fragment loading (default: `30`)

### Disabling Auto-Loading

To disable automatic fragment loading:

```powershell
$env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '0'
```

Or unregister the dispatcher:

```powershell
Unregister-CommandDispatcher
```

## Architecture

### Components

1. **FragmentCommandRegistry.psm1** - Command registry management

   - Registers commands with their fragments
   - Provides lookup and query functions
   - Supports export/import for caching

2. **FragmentLoader.psm1** - On-demand fragment loading

   - Loads fragments by name or command
   - Handles dependencies automatically
   - Respects fragment idempotency

3. **CommandDispatcher.psm1** - Automatic command detection

   - Hooks into CommandNotFoundAction
   - Automatically loads fragments for unknown commands
   - Chains with existing handlers

4. **generate-command-wrappers.ps1** - Wrapper generator
   - Generates standalone executable scripts
   - Creates wrappers in `scripts/bin/`
   - Supports single command or all commands

### Command Registration

Commands are automatically registered when fragments are loaded:

- `Set-AgentModeFunction` automatically registers functions
- `Set-AgentModeAlias` automatically registers aliases
- Registration uses `$global:CurrentFragmentContext` to identify source fragment

### Fragment Loading Flow

1. Command is called (e.g., `Invoke-Aws`)
2. Command dispatcher intercepts if command not found
3. Dispatcher checks registry for command
4. If found, loads fragment and dependencies
5. Command execution proceeds

## Examples

### Using Commands in -NoProfile Sessions

```powershell
# Start PowerShell without profile
pwsh -NoProfile

# Command dispatcher automatically loads fragment
Invoke-Aws --version
```

### Querying the Registry

```powershell
# Find all commands from a fragment
Get-CommandsForFragment -FragmentName 'aws'

# Check if a command exists
if (Test-CommandInRegistry -CommandName 'Invoke-Aws') {
    Write-Host "Command is available"
}

# Get command details
$info = Get-CommandRegistryInfo -CommandName 'Invoke-Aws'
Write-Host "Fragment: $($info.Fragment)"
Write-Host "Type: $($info.Type)"
```

### Using Standalone Wrappers

```powershell
# After generating wrappers and adding to PATH
Invoke-Aws --version

# Works from any shell
cmd /c Invoke-Aws --version
```

## Troubleshooting

### Commands Not Auto-Loading

1. Check if dispatcher is registered:

   ```powershell
   Test-CommandDispatcherRegistered
   ```

2. Check if auto-loading is enabled:

   ```powershell
   $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS
   ```

3. Manually register dispatcher:
   ```powershell
   Register-CommandDispatcher
   ```

### Commands Not in Registry

Commands are only registered when fragments are loaded. If a command isn't in the registry:

1. Load the fragment that contains the command
2. The command will be automatically registered

### Wrapper Generation Fails

If wrapper generation fails:

1. Ensure the profile has been loaded at least once (to populate registry)
2. Check that the command exists in the registry:
   ```powershell
   Test-CommandInRegistry -CommandName 'YourCommand'
   ```

## Related Documentation

- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Profile architecture
- [AGENTS.md](../../AGENTS.md) - AI coding assistant guidance
- [PROFILE_README.md](../../PROFILE_README.md) - Profile documentation

## See Also

- `Get-Help Register-FragmentCommand`
- `Get-Help Load-Fragment`
- `Get-Help Register-CommandDispatcher`
- `Get-Help generate-command-wrappers.ps1`
