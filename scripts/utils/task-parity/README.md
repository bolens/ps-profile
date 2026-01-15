# Task Parity Checker

A utility to ensure task parity across all task runner files in the repository.

## Overview

This utility checks that all tasks defined in `Taskfile.yml` are also present in:

- `Makefile`
- `package.json` (scripts section)
- `justfile`

It can also automatically generate missing tasks to achieve parity.

## Usage

### Check Parity (Report Only)

```powershell
# Using task runner
task check-task-parity
# or
make check-task-parity
# or
just check-task-parity
# or
pnpm run check-task-parity

# Direct execution
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1
```

### Generate Missing Tasks

```powershell
# Generate missing tasks in all files
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 -Generate

# Generate missing tasks in specific file
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 -Generate -TargetFile 'makefile'
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 -Generate -TargetFile 'package'
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 -Generate -TargetFile 'justfile'
```

## Features

- **Task Discovery**: Parses tasks from all supported task runner formats
- **Parity Checking**: Identifies missing tasks in each file
- **Command Comparison**: Detects command differences for the same task
- **Auto-Generation**: Automatically adds missing tasks in the correct format
- **Argument Normalization**: Handles different argument placeholder formats:
  - Taskfile: `{{.CLI_ARGS}}`
  - Makefile: `$(ARGS)`
  - Justfile: `{{arguments()}}`
  - package.json: (no arguments typically)

## Output

The script provides:

- Summary statistics (total tasks, unique task names)
- Missing tasks per file
- Command differences (if any)
- Exit code indicating parity status

## Examples

### Check for Missing Tasks

```powershell
$ pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1

Task Parity Checker
===================

Parsing task files...
  Parsing taskfile...
    Found 45 tasks
  Parsing makefile...
    Found 45 tasks
  Parsing package...
    Found 45 tasks
  Parsing justfile...
    Found 44 tasks

Comparing tasks...

Task Parity Report
==================

Summary:
  Total task definitions: 179
  Unique task names: 45

Missing Tasks by File:
  taskfile : No missing tasks
  makefile : No missing tasks
  package : No missing tasks
  justfile : 1 missing
    - clear-fragment-cache

Tip: Use -Generate to automatically add missing tasks.
```

### Generate Missing Tasks

```powershell
$ pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 -Generate

Generating missing tasks...
  Generating 1 tasks in justfile...
    Successfully generated tasks in justfile

Task generation complete. Please review the changes before committing.
```

## Module Structure

- `check-task-parity.ps1` - Main script
- `modules/TaskParser.psm1` - Parses tasks from different file formats
- `modules/TaskComparator.psm1` - Compares tasks across files
- `modules/TaskGenerator.psm1` - Generates missing tasks

## Notes

- The script uses `Taskfile.yml` as the reference source when generating missing tasks
- Command arguments are automatically converted to the appropriate format for each file type
- Complex tasks with dependencies (like `quality-check`) are preserved correctly
- The script respects PowerShell's `-WhatIf` parameter for safe testing

## Integration

This utility is integrated into the repository's task runners:

- Added as `check-task-parity` task in all task files
- Can be run as part of CI/CD validation
- Useful for maintaining consistency across different task runner preferences
