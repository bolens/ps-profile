<#
scripts/checks/check-commit-messages.ps1

.SYNOPSIS
    Validates commit messages against Conventional Commits format.

.DESCRIPTION
    Validates commit subjects in the current branch against Conventional Commits format.
    By default compares commits on HEAD against origin/main. Exits 0 when all commit
    subjects pass, non-zero when any fail. Allows merge commits, revert commits, and
    auto-merge commits.

.PARAMETER Base
    The base branch or commit to compare against. Defaults to 'origin/main'.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-commit-messages.ps1

    Validates commits against origin/main.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-commit-messages.ps1 -Base 'origin/develop'

    Validates commits against origin/develop.
#>

param(
    [string]$Base = 'origin/main'
)

Write-Output "Checking commits against base: $Base"

try {
    # Ensure we have the base ref locally
    & git fetch origin +refs/heads/main:refs/remotes/origin/main 2>$null
}
catch {
    # ignore
}

# Get commit list between base and HEAD (exclude merges)
$commits = & git rev-list --no-merges --reverse $Base..HEAD 2>$null
if (-not $commits) {
    Write-Output "No commits to check against $Base"
    exit 0
}

# Use List for better performance than array concatenation
$errors = [System.Collections.Generic.List[PSCustomObject]]::new()
$typeRegex = 'feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip|ci'
$convRegex = "^(?:($typeRegex))(?:\([a-z0-9_\-]+\))?:\s.+$"

# Compile regex patterns once for better performance
$mergeRegex = [regex]::new('^Merge\s', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$revertRegex = [regex]::new('^Revert\s', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$autoMergeRegex = [regex]::new('^Auto-merge', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$convRegexCompiled = [regex]::new($convRegex, [System.Text.RegularExpressions.RegexOptions]::Compiled)

foreach ($c in $commits) {
    $subject = (& git log -1 --pretty=format:%s $c).Trim()
    if (-not $subject) { continue }

    if ($mergeRegex.IsMatch($subject) -or $revertRegex.IsMatch($subject) -or $autoMergeRegex.IsMatch($subject)) {
        continue
    }

    if (-not $convRegexCompiled.IsMatch($subject)) {
        $errors.Add([PSCustomObject]@{ Commit = $c; Subject = $subject })
    }
}

if ($errors.Count -gt 0) {
    Write-Error "Found $($errors.Count) commit(s) with invalid commit subjects:"
    $errors | ForEach-Object { Write-Output ("Commit: {0} - {1}" -f $_.Commit, $_.Subject) }
    exit 1
}

Write-Output "All commit subjects conform to Conventional Commits"
exit 0
