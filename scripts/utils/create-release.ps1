<#
scripts/utils/create-release.ps1

.SYNOPSIS
    Creates a release based on conventional commits since the last tag.

.DESCRIPTION
    Analyzes commits since the last git tag and creates a new release version based on
    conventional commit patterns. Determines version bump (major/minor/patch) from commit
    types, generates a changelog, creates a git tag, and pushes it to the remote repository.

.PARAMETER DryRun
    If specified, performs a dry run without creating tags or pushing changes. Shows what
    would be done without making any changes.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\create-release.ps1

    Creates a release by analyzing commits and creating a new git tag.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\create-release.ps1 -DryRun

    Shows what release would be created without actually creating it.
#>

param(
    [switch]$DryRun
)

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

Write-ScriptMessage -Message "Analyzing commits for release..."

# Get the latest tag
$latestTag = git describe --tags --abbrev=0 2>$null
if (-not $latestTag) {
    $latestTag = "HEAD~1"  # If no tags, compare to initial commit
}

Write-ScriptMessage -Message "Comparing commits from $latestTag to HEAD..."

# Compile regex patterns once for better performance
$regexBreaking = [regex]::new('^feat!|^BREAKING|^break!', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$regexFeat = [regex]::new('^feat', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexFix = [regex]::new('^fix', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexVersion = [regex]::new('v(\d+\.\d+\.\d+)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Analyze commits using conventional commit patterns
$commits = git log --pretty=format:"%s" "$latestTag..HEAD" 2>$null

$breakingChanges = 0
$features = 0
$fixes = 0
$other = 0

foreach ($commit in $commits) {
    if ($regexBreaking.IsMatch($commit)) {
        $breakingChanges++
    }
    elseif ($regexFeat.IsMatch($commit)) {
        $features++
    }
    elseif ($regexFix.IsMatch($commit)) {
        $fixes++
    }
    else {
        $other++
    }
}

Write-ScriptMessage -Message "Analysis results:"
Write-ScriptMessage -Message "  Breaking changes: $breakingChanges"
Write-ScriptMessage -Message "  Features: $features"
Write-ScriptMessage -Message "  Fixes: $fixes"
Write-ScriptMessage -Message "  Other: $other"

# Determine version bump
$versionBump = "patch"
if ($breakingChanges -gt 0) {
    $versionBump = "major"
}
elseif ($features -gt 0) {
    $versionBump = "minor"
}

Write-ScriptMessage -Message "Recommended version bump: $versionBump"

# Get current version from git tags or package file
$currentVersion = "0.0.0"
if ($latestTag) {
    $versionMatch = $regexVersion.Match($latestTag)
    if ($versionMatch.Success) {
        $currentVersion = $versionMatch.Groups[1].Value
    }
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
Write-ScriptMessage -Message "New version would be: $newVersion"

if ($DryRun) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "`nDRY RUN - No changes made"
}

# Generate changelog
Write-ScriptMessage -Message "`nGenerating changelog..."
try {
    & (Join-Path $PSScriptRoot 'generate-changelog.ps1') -Unreleased
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to generate changelog"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Create git tag
Write-ScriptMessage -Message "Creating git tag v$newVersion..."
try {
    git tag -a "v$newVersion" -m "Release v$newVersion"
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to create git tag"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Push tag
Write-ScriptMessage -Message "Pushing tag to remote..."
try {
    git push origin "v$newVersion"
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to push tag to remote"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "`nRelease v$newVersion created successfully!`nGitHub Actions will automatically create the GitHub release."