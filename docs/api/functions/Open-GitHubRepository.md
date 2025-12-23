# Open-GitHubRepository

## Synopsis

Opens a GitHub repository in the web browser.

## Description

Opens the current repository or a specified repository in the GitHub web interface.

## Signature

```powershell
Open-GitHubRepository
```

## Parameters

### -Repository

Optional repository path (e.g., "owner/repo"). If not specified, opens the current repository.


## Examples

### Example 1

`powershell
Open-GitHubRepository
``

### Example 2

`powershell
Open-GitHubRepository -Repository "microsoft/vscode"
``

## Aliases

This function has the following aliases:

- `gh-open` - Opens a GitHub repository in the web browser.


## Source

Defined in: ..\profile.d\20-gh.ps1
