# New-GitHubPullRequest

## Synopsis

Creates a GitHub pull request.

## Description

Creates a new pull request using the GitHub CLI (gh). Forwards all arguments to gh pr create.

## Signature

```powershell
New-GitHubPullRequest
```

## Parameters

### -Arguments

Arguments forwarded to gh pr create.


## Examples

### Example 1

```powershell
New-GitHubPullRequest --title 'Fix bug' --body 'Details here'
```

## Aliases

This function has the following aliases:

- `prc` - GitHub PR create - create a pull request


## Source

Defined in: ../profile.d/git-modules/integrations/git-github.ps1
