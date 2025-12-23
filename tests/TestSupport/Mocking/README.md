# Mocking Framework - Modular Structure

The mocking framework is organized into focused, maintainable modules.

## Module Structure

```
Mocking/
├── README.md              # This file
├── MockRegistry.psm1      # Mock management and registry (~100 lines)
├── MockCommand.psm1       # Command mocking (~200 lines)
├── MockFileSystem.psm1    # File system mocking (~100 lines)
├── MockNetwork.psm1       # Network mocking (~100 lines)
├── MockEnvironment.psm1   # Environment variable mocking (~80 lines)
└── PesterMocks.psm1       # Pester 5 mocking helpers (~250 lines)
```

All modules are automatically imported by `TestSupport.ps1` when tests are loaded.

## Module Responsibilities

### MockRegistry.psm1

- `Register-Mock` - Tracks mocks for cleanup
- `Clear-MockRegistry` - Clears mock registry
- `Restore-AllMocks` - Restores original values
- `Get-MockRegistry` - Inspects mock registry

### MockCommand.psm1

- `Mock-Command` - Mocks external commands
- `Mock-Commands` - Mocks multiple commands
- `Mock-CommandAvailability` - Mocks command availability (function-based)

### MockFileSystem.psm1

- `Mock-FileSystem` - Mocks file system operations

### MockNetwork.psm1

- `Mock-Network` - Mocks network operations

### MockEnvironment.psm1

- `Mock-EnvironmentVariable` - Mocks environment variables
- `Restore-EnvironmentVariable` - Restores environment variables

### PesterMocks.psm1

- `Use-PesterMock` - Pester 5 mock wrapper
- `Assert-MockCalled` - Verifies mock calls
- `Mock-CommandAvailabilityPester` - Pester 5 command availability mocking
- `Initialize-PesterMocks` - Sets up common Pester 5 mocks

## Usage

All mocking modules are automatically loaded by `TestSupport.ps1`. No manual import is needed in tests.

If you need to import individual modules manually (e.g., in a script outside the test framework):

```powershell
# Import MockRegistry first (dependency)
Import-Module (Join-Path $PSScriptRoot 'TestSupport' 'Mocking' 'MockRegistry.psm1') -Force

# Then import specific modules as needed
Import-Module (Join-Path $PSScriptRoot 'TestSupport' 'Mocking' 'MockCommand.psm1') -Force
```

## Benefits of Modular Structure

1. **Maintainability** - Each module is focused and easy to understand
2. **Testability** - Modules can be tested independently
3. **Performance** - Only load what you need
4. **Clarity** - Clear separation of concerns
5. **Size** - Each module is under 300 lines, easy to review

## Adding New Mocking Capabilities

To add new mocking functionality:

1. Create a new module file (e.g., `MockDatabase.psm1`)
2. Import `MockRegistry.psm1` for tracking
3. Implement your mocking functions
4. Update `TestSupport.ps1` to import your new module
5. Update this README

## See Also

- `../MOCKING.md` - Comprehensive usage documentation
- `../TestMocks.ps1` - Legacy test mocks for test mode
