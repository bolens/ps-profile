# Cross-platform helper invoked by .git/hooks/pre-commit
# It runs formatting, adds formatted files, then runs validation.

# Run formatting first
$formatScript = Join-Path $PSScriptRoot '..\utils\run-format.ps1'
if (Test-Path $formatScript) {
    Write-Output "Running code formatting..."
    & pwsh -NoProfile -File $formatScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Code formatting failed"
        exit $LASTEXITCODE
    }

    # Add any files that were formatted
    $formattedFiles = & git diff --name-only
    if ($formattedFiles) {
        Write-Output "Adding formatted files to commit..."
        $formattedFiles | ForEach-Object { & git add $_ }
    }
}
else {
    Write-Warning "Format script not found: $formatScript"
}

# Run validation
$validateScript = Join-Path $PSScriptRoot '..\checks\validate-profile.ps1'
if (-not (Test-Path $validateScript)) {
    Write-Error "Validation script not found: $validateScript"
    exit 1
}

Write-Output "Running validation..."
& pwsh -NoProfile -File $validateScript -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output "Pre-commit checks passed"
exit 0
