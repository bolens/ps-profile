# Release-GoProject

## Synopsis

Creates Go project releases using goreleaser.

## Description

Wrapper function for goreleaser, which automates the release process for Go projects including building binaries for multiple platforms, creating archives, and publishing releases.

## Signature

```powershell
Release-GoProject
```

## Parameters

### -Arguments

Additional arguments to pass to goreleaser. Can be used multiple times or as an array.


## Outputs

System.String. Output from goreleaser execution.


## Examples

### Example 1

`powershell
Release-GoProject
        Creates a release using goreleaser.
``

### Example 2

`powershell
Release-GoProject --snapshot
        Creates a snapshot release (dry-run).
``

### Example 3

`powershell
Release-GoProject --skip-publish
        Builds release artifacts without publishing.
``

## Aliases

This function has the following aliases:

- `goreleaser` - Creates Go project releases using goreleaser.


## Source

Defined in: ..\profile.d\lang-go.ps1
