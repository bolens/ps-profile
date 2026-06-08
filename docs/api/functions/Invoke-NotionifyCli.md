# Invoke-NotionifyCli

## Synopsis

Invokes notionify-cli with standard argument forwarding.

## Description

Wrapper for notionify-cli convert/push/pull/sync commands.

## Signature

```powershell
Invoke-NotionifyCli
```

## Parameters

### -Command

notionify-cli subcommand (convert, push, pull, sync).

### -Arguments

Additional arguments forwarded to notionify-cli.


## Outputs

CLI output from notionify-cli. .EXAMPLE Invoke-NotionifyCli


## Examples

### Example 1

`powershell
Invoke-NotionifyCli
``

## Aliases

This function has the following aliases:

- `notionify` - Invokes notionify-cli with standard argument forwarding.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
