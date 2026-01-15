# Invoke-GitHubPullRequest

## Synopsis

Manages GitHub pull requests.

## Description

Wrapper for GitHub CLI pull request commands.

## Signature

```powershell
Invoke-GitHubPullRequest
```

## Parameters

### -Arguments

Arguments to pass to gh pr.


## Examples

### Example 1

`powershell
Invoke-GitHubPullRequest list
``

### Example 2

`powershell
Invoke-GitHubPullRequest create --title "My PR"
``

## Aliases

This function has the following aliases:

- `gh-pr` - Manages GitHub pull requests.


## Source

Defined in: ..\profile.d\gh.ps1
