<#
scripts/check-commit-messages.ps1

Validate commit subjects in the current branch against Conventional Commits.
By default compares commits on HEAD against origin/main. Exits 0 when all
commit subjects pass, non-zero when any fail.

Usage:
  pwsh -NoProfile -File scripts/checks/check-commit-messages.ps1
#>

param(
    [string]$Base = 'origin/main'
)

Write-Output "Checking commits against base: $Base"

try {
    # Ensure we have the base ref locally
    & git fetch origin +refs/heads/main:refs/remotes/origin/main 2>$null
} catch {
    # ignore
}

# Get commit list between base and HEAD (exclude merges)
$commits = & git rev-list --no-merges --reverse $Base..HEAD 2>$null
if (-not $commits) {
    Write-Output "No commits to check against $Base"
    exit 0
}

$errors = @()
$typeRegex = 'feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip|ci'
$convRegex = "^(?:($typeRegex))(?:\([a-z0-9_\-]+\))?:\s.+$"

foreach ($c in $commits) {
    $subject = (& git log -1 --pretty=format:%s $c).Trim()
    if (-not $subject) { continue }

    if ($subject -match '^Merge\s' -or $subject -match '^Revert\s' -or $subject -match '^Auto-merge') {
        continue
    }

    if ($subject -notmatch $convRegex) {
        $errors += [PSCustomObject]@{ Commit = $c; Subject = $subject }
    }
}

if ($errors.Count -gt 0) {
    Write-Error "Found $($errors.Count) commit(s) with invalid commit subjects:"
    $errors | ForEach-Object { Write-Output ("Commit: {0} - {1}" -f $_.Commit, $_.Subject) }
    exit 1
}

Write-Output "All commit subjects conform to Conventional Commits"
exit 0
