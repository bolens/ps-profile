<#
scripts/git/hooks/commit-msg.ps1

.SYNOPSIS
    Validates commit messages against Conventional Commits format.

.DESCRIPTION
    Conventional Commits validator. Accepts messages matching the pattern:
    type(scope?): subject
    
    Examples:
      feat: add new widget
      fix(cli): handle empty input
    
    This script also allows:
     - Merge commits (messages that start with "Merge ")
     - Revert commits (messages that start with "Revert ")
     - Auto-merge commits (messages that start with "Auto-merge")

.PARAMETER CommitMsgFile
    The path to the commit message file. This is automatically provided by git
    when the hook is invoked.

.EXAMPLE
    git commit -m "feat: add new feature"
    
    This hook is automatically invoked by git when committing.
#>

param(
    [string]$CommitMsgFile
)

if (-not $CommitMsgFile -or -not (Test-Path $CommitMsgFile)) {
    Write-Error "commit-msg: commit message file not provided or not found"
    exit 2
}

$msg = Get-Content -Path $CommitMsgFile -Raw
$lines = $msg -split "`n"
$subject = $lines[0].Trim()

if (-not $subject) {
    Write-Error "commit-msg: empty commit message"
    exit 1
}

# Compile regex patterns once for better performance
$mergeRegex = [regex]::new('^Merge\s', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$revertRegex = [regex]::new('^Revert\s', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$autoMergeRegex = [regex]::new('^Auto-merge', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Allow merge/revert commits and automated PR title formats
if ($mergeRegex.IsMatch($subject) -or $revertRegex.IsMatch($subject) -or $autoMergeRegex.IsMatch($subject)) {
    Write-Output "commit-msg: merge/revert/auto-merge message allowed"
    exit 0
}

# Conventional Commit regex: type(scope?)?: subject
# type: feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip
$typeRegex = 'feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip|ci'
$convRegex = "^(?:($typeRegex))(?:\([a-z0-9_\-]+\))?:\s.+$"
$convRegexCompiled = [regex]::new($convRegex, [System.Text.RegularExpressions.RegexOptions]::Compiled)

if (-not $convRegexCompiled.IsMatch($subject)) {
    Write-Error "commit-msg: commit subject does not match Conventional Commits pattern (type(scope?): subject). Example: 'feat(cli): add foo'"
    exit 1
}

# Enforce subject length
$max = 72
if ($subject.Length -gt $max) {
    Write-Error "commit-msg: subject length ($($subject.Length)) exceeds $max characters"
    exit 1
}

Write-Output "commit-msg: OK (Conventional Commit)"
exit 0
