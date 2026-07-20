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
    [Parameter(Position = 0)]
    [string]$CommitMsgFile
)

# This script lives at scripts/git/hooks/commit-msg.ps1 → scripts/ is two levels up.
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if (-not (Test-Path -LiteralPath $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if (-not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'RegexUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

if (-not $CommitMsgFile -or [string]::IsNullOrWhiteSpace($CommitMsgFile) -or -not (Test-Path -LiteralPath $CommitMsgFile)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message 'commit-msg: commit message file not provided or not found'
}

$msg = Get-Content -Path $CommitMsgFile -Raw
$lines = $msg -split "`n"
$subject = $lines[0].Trim()

if (-not $subject) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'commit-msg: empty commit message'
}

# Create compiled regex patterns using RegexUtilities module
$mergeRegex = New-CompiledRegex -Pattern '^Merge\s'
$revertRegex = New-CompiledRegex -Pattern '^Revert\s'
$autoMergeRegex = New-CompiledRegex -Pattern '^Auto-merge'

# Allow merge/revert commits and automated PR title formats
if ($mergeRegex.IsMatch($subject) -or $revertRegex.IsMatch($subject) -or $autoMergeRegex.IsMatch($subject)) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'commit-msg: merge/revert/auto-merge message allowed'
}

# Conventional Commit regex: type(scope?)?: subject
$typeRegex = 'feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|wip'
$convRegex = "^(?:($typeRegex))(?:\([a-z0-9_\-]+\))?:\s.+$"
$convRegexCompiled = [regex]::new($convRegex, [System.Text.RegularExpressions.RegexOptions]::Compiled)

if (-not $convRegexCompiled.IsMatch($subject)) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "commit-msg: commit subject does not match Conventional Commits pattern (type(scope?): subject). Example: 'feat(cli): add foo'"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'commit-msg: commit message looks good'
