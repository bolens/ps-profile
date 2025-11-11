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

# Import shared utilities
# Note: Git hooks may be called from .git/hooks/, so we need to resolve the path carefully
$hookScriptPath = $MyInvocation.MyCommand.Definition
$hookDir = Split-Path -Parent $hookScriptPath
# From .git/hooks/, go up two levels to get repo root
$repoRoot = Split-Path -Parent (Split-Path -Parent $hookDir)
$commonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

if (-not $CommitMsgFile -or -not (Test-Path $CommitMsgFile)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "commit-msg: commit message file not provided or not found"
}

$msg = Get-Content -Path $CommitMsgFile -Raw
$lines = $msg -split "`n"
$subject = $lines[0].Trim()

if (-not $subject) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "commit-msg: empty commit message"
}

# Compile regex patterns once for better performance
$mergeRegex = [regex]::new('^Merge\s', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$revertRegex = [regex]::new('^Revert\s', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$autoMergeRegex = [regex]::new('^Auto-merge', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Allow merge/revert commits and automated PR title formats
if ($mergeRegex.IsMatch($subject) -or $revertRegex.IsMatch($subject) -or $autoMergeRegex.IsMatch($subject)) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "commit-msg: merge/revert/auto-merge message allowed"
}

# Conventional Commit regex: type(scope?)?: subject
# type: feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip
$typeRegex = 'feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip|ci'
$convRegex = "^(?:($typeRegex))(?:\([a-z0-9_\-]+\))?:\s.+$"
$convRegexCompiled = [regex]::new($convRegex, [System.Text.RegularExpressions.RegexOptions]::Compiled)

if (-not $convRegexCompiled.IsMatch($subject)) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "commit-msg: commit subject does not match Conventional Commits pattern (type(scope?): subject). Example: 'feat(cli): add foo'"
}

# Enforce subject length
$max = 72
if ($subject.Length -gt $max) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "commit-msg: subject length ($($subject.Length)) exceeds $max characters"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "commit-msg: OK (Conventional Commit)"

