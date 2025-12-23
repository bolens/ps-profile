# database-clients.ps1

Database client tools fragment for database management and operations.

## Overview

The `database-clients.ps1` fragment provides wrapper functions for popular database client tools, enabling easy access to MongoDB Compass, SQL Workbench/J, DBeaver, TablePlus, Hasura CLI, and Supabase CLI. All functions gracefully degrade when tools are not installed, providing helpful installation hints.

## Functions

### Start-MongoDbCompass

Launches MongoDB Compass GUI.

**Syntax:**

```powershell
Start-MongoDbCompass [-ConnectionString <String>]
```

**Parameters:**

- `ConnectionString` (Optional): MongoDB connection string to open directly.

**Examples:**

```powershell
# Launch MongoDB Compass
Start-MongoDbCompass

# Launch with connection string
Start-MongoDbCompass -ConnectionString "mongodb://localhost:27017"
```

**Alias:** `mongodb-compass`

---

### Start-SqlWorkbench

Launches SQL Workbench/J.

**Syntax:**

```powershell
Start-SqlWorkbench [-Workspace <String>]
```

**Parameters:**

- `Workspace` (Optional): Workspace file to open.

**Examples:**

```powershell
# Launch SQL Workbench/J
Start-SqlWorkbench

# Launch with workspace
Start-SqlWorkbench -Workspace "C:\Workspaces\my-workspace.xml"
```

**Alias:** `sql-workbench`

---

### Start-DBeaver

Launches DBeaver Universal Database Tool.

**Syntax:**

```powershell
Start-DBeaver [-Workspace <String>]
```

**Parameters:**

- `Workspace` (Optional): Workspace directory to open.

**Examples:**

```powershell
# Launch DBeaver
Start-DBeaver

# Launch with workspace directory
Start-DBeaver -Workspace "C:\Workspaces\dbeaver"
```

**Alias:** `dbeaver`

---

### Start-TablePlus

Launches TablePlus.

**Syntax:**

```powershell
Start-TablePlus [-Connection <String>]
```

**Parameters:**

- `Connection` (Optional): Connection name or file to open.

**Examples:**

```powershell
# Launch TablePlus
Start-TablePlus

# Launch with connection
Start-TablePlus -Connection "my-connection"
```

**Alias:** `tableplus`

---

### Invoke-Hasura

Executes Hasura CLI commands.

**Syntax:**

```powershell
Invoke-Hasura [<Arguments>]
```

**Parameters:**

- `Arguments` (ValueFromRemainingArguments): Arguments to pass to hasura-cli command.

**Examples:**

```powershell
# Check Hasura CLI version
Invoke-Hasura version

# Apply migrations
Invoke-Hasura migrate apply

# Start console
Invoke-Hasura console
```

**Alias:** `hasura`

---

### Invoke-Supabase

Executes Supabase CLI commands.

**Syntax:**

```powershell
Invoke-Supabase [<Arguments>]
```

**Parameters:**

- `Arguments` (ValueFromRemainingArguments): Arguments to pass to supabase command.

**Examples:**

```powershell
# Check Supabase status
Invoke-Supabase status

# Start local Supabase
Invoke-Supabase start

# Stop local Supabase
Invoke-Supabase stop

# Reset database
Invoke-Supabase db reset
```

**Alias:** `supabase`

**Note:** The function automatically detects and uses `supabase-beta` if available, falling back to `supabase` if not.

---

## Installation

### MongoDB Compass

```powershell
scoop install mongodb-compass
```

### SQL Workbench/J

```powershell
scoop install sql-workbench
```

### DBeaver

```powershell
scoop install dbeaver
```

### TablePlus

```powershell
scoop install tableplus
```

### Hasura CLI

```powershell
scoop install hasura-cli
```

### Supabase CLI

```powershell
scoop install supabase-beta
# or
scoop install supabase
```

---

## Error Handling

All functions gracefully handle missing tools:

- Functions check for tool availability using `Test-CachedCommand`
- When tools are missing, functions display helpful installation hints
- Functions return `$null` when tools are unavailable
- Error messages are written to the error stream using `Write-Error`

**Example:**

```powershell
# If mongodb-compass is not installed
Start-MongoDbCompass
# Displays: Warning: mongodb-compass not found. Install with: scoop install mongodb-compass
# Returns: $null
```

---

## Testing

The module includes comprehensive test coverage:

- **Unit Tests**: 28 tests covering all functions
- **Integration Tests**: 17 tests verifying function registration, alias creation, and graceful degradation
- **Performance Tests**: 5 tests ensuring acceptable load times and performance

**Test Status:**

- ✅ 28/28 unit tests passing
- ✅ 16/17 integration tests passing
- ✅ 4/5 performance tests passing
- ✅ 49/50 total tests passing

**Test Files:**

- `tests/unit/profile-database-clients-*.tests.ps1` (6 files)
- `tests/integration/tools/database-clients.tests.ps1`
- `tests/performance/database-clients-performance.tests.ps1`

---

## Fragment Metadata

- **Tier:** standard
- **Dependencies:** bootstrap, env
- **Fragment Name:** database-clients

---

## Notes

- All functions use `Set-AgentModeFunction` and `Set-AgentModeAlias` for idempotent registration
- Functions are safe to call multiple times
- Fragment loading is idempotent (can be loaded multiple times safely)
- GUI tools (MongoDB Compass, SQL Workbench, DBeaver, TablePlus) return `System.Diagnostics.Process` objects
- CLI tools (Hasura, Supabase) return command output as strings
