<#
scripts/utils/code-quality/modules/TestGitIntegration.psm1

.SYNOPSIS
    Git integration utilities for test discovery.

.DESCRIPTION
    Provides functions for detecting changed files in git and mapping them to test files.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Gets files changed in the git working directory.

.DESCRIPTION
    Returns a list of files that have been modified, added, or deleted in the working directory.
    Excludes untracked files unless -IncludeUntracked is specified.

.PARAMETER IncludeUntracked
    Include untracked files in the results.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    System.String[] - Array of changed file paths
#>
function Get-GitChangedFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [switch]$IncludeUntracked,
        [string]$RepoRoot
    )

    # Check if git command is available
    $gitCommand = Get-Command 'git' -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        Write-ScriptMessage -Message "Git is not available. Cannot detect changed files." -LogLevel 'Warning'
        return @()
    }

    Push-Location $RepoRoot
    try {
        # Reset LASTEXITCODE before checking
        $global:LASTEXITCODE = 0
        
        # Check if we're in a git repository
        $null = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ScriptMessage -Message "Not in a git repository. Cannot detect changed files." -LogLevel 'Warning'
            return @()
        }
        
        # Reset LASTEXITCODE after successful check
        $global:LASTEXITCODE = 0

        $changedFiles = @()

        # Get modified, added, and deleted files
        $gitStatus = git status --porcelain 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitStatus) {
            $changedFiles = $gitStatus | ForEach-Object {
                $line = $_.Trim()
                if ($line -match '^[MADRC]+\s+(.+)$') {
                    $filePath = $matches[1]
                    # Handle renamed files (R100 old -> new)
                    if ($filePath -match '^(.+?)\s+->\s+(.+)$') {
                        $matches[2]  # Return the new file path
                    }
                    else {
                        $filePath
                    }
                }
                elseif ($IncludeUntracked -and $line -match '^\?\?\s+(.+)$') {
                    $matches[1]  # Untracked files
                }
            } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | 
            ForEach-Object { 
                $fullPath = Join-Path $RepoRoot $_
                if ($fullPath -and -not [string]::IsNullOrWhiteSpace($fullPath) -and (Test-Path -LiteralPath $fullPath)) {
                    (Resolve-Path $fullPath).ProviderPath
                }
            }
        }

        return $changedFiles | Select-Object -Unique
    }
    finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Gets files changed since a specific commit or branch.

.DESCRIPTION
    Returns a list of files that have been changed since the specified commit or branch.

.PARAMETER Since
    Commit hash, branch name, or tag to compare against. Defaults to 'HEAD~1' if not specified.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    System.String[] - Array of changed file paths
#>
function Get-GitChangedFilesSince {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$Since = 'HEAD~1',
        [string]$RepoRoot
    )

    # Check if git command is available
    $gitCommand = Get-Command 'git' -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        Write-ScriptMessage -Message "Git is not available. Cannot detect changed files." -LogLevel 'Warning'
        return @()
    }

    Push-Location $RepoRoot
    try {
        # Reset LASTEXITCODE before checking
        $global:LASTEXITCODE = 0
        
        # Check if we're in a git repository
        $null = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ScriptMessage -Message "Not in a git repository. Cannot detect changed files." -LogLevel 'Warning'
            return @()
        }
        
        # Reset LASTEXITCODE after successful check
        $global:LASTEXITCODE = 0

        # Verify the commit/branch exists
        $null = git rev-parse --verify "$Since" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ScriptMessage -Message "Invalid git reference: $Since" -LogLevel 'Warning'
            return @()
        }
        
        # Reset LASTEXITCODE after verification
        $global:LASTEXITCODE = 0

        # Get changed files
        $changedFiles = git diff --name-only "$Since" 2>$null
        if ($LASTEXITCODE -eq 0 -and $changedFiles) {
            return $changedFiles | ForEach-Object {
                $fullPath = Join-Path $RepoRoot $_
                if ($fullPath -and -not [string]::IsNullOrWhiteSpace($fullPath) -and (Test-Path -LiteralPath $fullPath)) {
                    (Resolve-Path $fullPath).ProviderPath
                }
            } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        }

        return @()
    }
    finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Maps source files to their corresponding test files.

.DESCRIPTION
    Given a list of source files, finds the corresponding test files.
    Tests are matched by name pattern (e.g., script.ps1 -> script.tests.ps1)
    or by directory structure (e.g., profile.d/file.ps1 -> tests/integration/file.tests.ps1).

.PARAMETER SourceFiles
    Array of source file paths to map to tests.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    System.String[] - Array of test file paths
#>
function Get-TestFilesForSourceFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string[]]$SourceFiles,
        [string]$RepoRoot
    )

    $testFiles = @()
    $testsDir = Join-Path $RepoRoot 'tests'

    foreach ($sourceFile in $SourceFiles) {
        if ($sourceFile -and -not [string]::IsNullOrWhiteSpace($sourceFile) -and -not (Test-Path -LiteralPath $sourceFile)) {
            continue
        }

        $sourceRelative = $sourceFile.Replace($RepoRoot, '').TrimStart('\', '/')
        $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile)
        $sourceDir = Split-Path $sourceFile -Parent

        # Strategy 1: Look for test file with same name in tests directory
        $possibleTestPaths = @(
            Join-Path $testsDir 'unit' "$sourceName.tests.ps1",
            Join-Path $testsDir 'integration' "$sourceName.tests.ps1",
            Join-Path $testsDir 'performance' "$sourceName.tests.ps1",
            Join-Path $testsDir "$sourceName.tests.ps1"
        )

        foreach ($testPath in $possibleTestPaths) {
            if ($testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)) {
                $testFiles += $testPath
                break
            }
        }

        # Strategy 2: If source is in profile.d, look for corresponding test
        if ($sourceRelative -like 'profile.d\*' -or $sourceRelative -like 'profile.d/*') {
            $relativePath = $sourceRelative -replace '^profile\.d[\\/]', ''
            $testRelativePath = $relativePath -replace '\.ps1$', '.tests.ps1'
            
            $possibleTestPaths = @(
                Join-Path $testsDir 'integration' $testRelativePath,
                Join-Path $testsDir 'unit' $testRelativePath
            )

            foreach ($testPath in $possibleTestPaths) {
                if ($testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)) {
                    $testFiles += $testPath
                    break
                }
            }
        }

        # Strategy 3: If source is in scripts, look for corresponding test
        if ($sourceRelative -like 'scripts\*' -or $sourceRelative -like 'scripts/*') {
            $relativePath = $sourceRelative -replace '^scripts[\\/]', ''
            $testRelativePath = $relativePath -replace '\.ps1$', '.tests.ps1'
            
            $possibleTestPaths = @(
                Join-Path $testsDir 'unit' $testRelativePath,
                Join-Path $testsDir 'integration' $testRelativePath
            )

            foreach ($testPath in $possibleTestPaths) {
                if ($testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)) {
                    $testFiles += $testPath
                    break
                }
            }
        }

        # Strategy 4: If the file itself is a test file, include it
        if ($sourceFile -like '*.tests.ps1') {
            $testFiles += $sourceFile
        }
    }

    return $testFiles | Select-Object -Unique | Sort-Object
}

Export-ModuleMember -Function @(
    'Get-GitChangedFiles',
    'Get-GitChangedFilesSince',
    'Get-TestFilesForSourceFiles'
)

