<#
scripts/hooks/commit-msg.ps1

Conventional Commits validator. Accepts messages matching the pattern:
  type(scope?): subject

Examples:
  feat: add new widget
  fix(cli): handle empty input

This script also allows:
 - Merge commits (messages that start with "Merge ")
 - Revert commits (messages that start with "Revert ")

Usage: git will invoke this with the path to the commit message file.
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

# Allow merge/revert commits and automated PR title formats
if ($subject -match '^Merge\s' -or $subject -match '^Revert\s' -or $subject -match '^Auto-merge') {
    Write-Output "commit-msg: merge/revert/auto-merge message allowed"
    exit 0
}

# Conventional Commit regex: type(scope?)?: subject
# type: feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip
$typeRegex = 'feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip|ci'
$convRegex = "^(?:($typeRegex))(?:\([a-z0-9_\-]+\))?:\s.+$"

if ($subject -notmatch $convRegex) {
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
