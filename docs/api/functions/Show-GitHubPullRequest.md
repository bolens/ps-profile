# Show-GitHubPullRequest

## Synopsis

Views a GitHub pull request in the browser.

## Description

Opens a pull request in the default browser using the GitHub CLI (gh). Forwards all arguments to gh pr view --web.

## Signature

```powershell
Show-GitHubPullRequest
```

## Parameters

### -a

Arguments forwarded to gh pr view --web.


## Examples

### Example 1

`powershell
Show-GitHubPullRequest 42
.PARAMETER a
    Arguments forwarded to gh pr view --web.
``

## Aliases

This function has the following aliases:

- `prv` - GitHub PR view - view pull request in browser


## Source

Defined in: ../profile.d/git-modules/integrations/git-github.ps1
