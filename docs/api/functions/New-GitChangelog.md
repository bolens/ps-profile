# New-GitChangelog

## Synopsis

Generates a changelog using git-cliff.

## Description

Creates a changelog from Git history using git-cliff. Supports various output formats and configuration options.

## Signature

```powershell
New-GitChangelog
```

## Parameters

### -OutputPath

Path to save the changelog file. Defaults to CHANGELOG.md.

### -ConfigPath

Path to git-cliff configuration file.

### -Tag

Git tag to use as the starting point for the changelog.

### -Latest

Generate changelog only for the latest tag.


## Outputs

System.String. Path to the generated changelog file.


## Examples

### Example 1

`powershell
New-GitChangelog
        
        Generates a changelog in the current directory.
``

### Example 2

`powershell
New-GitChangelog -OutputPath "docs/CHANGELOG.md" -Latest
        
        Generates a changelog for the latest tag and saves it to docs/CHANGELOG.md.
``

## Aliases

This function has the following aliases:

- `git-cliff` - Generates a changelog using git-cliff.


## Source

Defined in: ..\profile.d\git-enhanced.ps1
