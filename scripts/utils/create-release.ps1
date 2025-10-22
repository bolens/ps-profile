<#
scripts/utils/create-release.ps1

Creates a release based on conventional commits since the last tag.

Usage: pwsh -NoProfile -File scripts/utils/create-release.ps1 [-DryRun]
#>

param(
    [switch]$DryRun
)

Write-Output "Analyzing commits for release..."

# Get the latest tag
$latestTag = git describe --tags --abbrev=0 2>$null
if (-not $latestTag) {
    $latestTag = "HEAD~1"  # If no tags, compare to initial commit
}

Write-Output "Comparing commits from $latestTag to HEAD..."

# Analyze commits using conventional commit patterns
$commits = git log --pretty=format:"%s" "$latestTag..HEAD" 2>$null

$breakingChanges = 0
$features = 0
$fixes = 0
$other = 0

foreach ($commit in $commits) {
    if ($commit -match '^feat!|^BREAKING|^break!') {
        $breakingChanges++
    } elseif ($commit -match '^feat') {
        $features++
    } elseif ($commit -match '^fix') {
        $fixes++
    } else {
        $other++
    }
}

Write-Output "Analysis results:"
Write-Output "  Breaking changes: $breakingChanges"
Write-Output "  Features: $features"
Write-Output "  Fixes: $fixes"
Write-Output "  Other: $other"

# Determine version bump
$versionBump = "patch"
if ($breakingChanges -gt 0) {
    $versionBump = "major"
} elseif ($features -gt 0) {
    $versionBump = "minor"
}

Write-Output "Recommended version bump: $versionBump"

# Get current version from git tags or package file
$currentVersion = "0.0.0"
if ($latestTag -and $latestTag -match 'v(\d+\.\d+\.\d+)') {
    $currentVersion = $matches[1]
}

$versionParts = $currentVersion -split '\.'
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

switch ($versionBump) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
    }
    "minor" {
        $minor++
        $patch = 0
    }
    "patch" {
        $patch++
    }
}

$newVersion = "$major.$minor.$patch"
Write-Output "New version would be: $newVersion"

if ($DryRun) {
    Write-Output "`nDRY RUN - No changes made"
    exit 0
}

# Generate changelog
Write-Output "`nGenerating changelog..."
& (Join-Path $PSScriptRoot 'generate-changelog.ps1') -Unreleased

# Create git tag
Write-Output "Creating git tag v$newVersion..."
git tag -a "v$newVersion" -m "Release v$newVersion"

# Push tag
Write-Output "Pushing tag to remote..."
git push origin "v$newVersion"

Write-Output "`nRelease v$newVersion created successfully!"
Write-Output "GitHub Actions will automatically create the GitHub release."