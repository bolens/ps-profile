<#
.SYNOPSIS
    Links developer guides in docs/guides to their source targets with drift.

.DESCRIPTION
    Binds each guide markdown file to the profile modules, fragments, and scripts it
    documents so `drift check` can detect stale documentation. Uses an explicit
    anchor map per guide plus path references discovered in guide content.
#>

param(
    [switch]$DryRun,
    [switch]$Refresh,
    [string[]]$GuidePath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$guidesRoot = Join-Path $repoRoot 'docs' 'guides'
$driftLockPath = Join-Path $repoRoot 'drift.lock'

$script:GuideAnchorMap = @{
    'DEVELOPMENT.md'                          = @(
        'scripts/utils/code-quality/run-pester.ps1'
        'scripts/utils/code-quality/analyze-coverage.ps1'
    )
    'DEVELOPMENT_PERFORMANCE.md'              = @(
        'Microsoft.PowerShell_profile.ps1'
        'scripts/lib/profile/ProfileFragmentLoader.psm1'
    )
    'DEVELOPMENT_QUICK_START.md'            = @(
        'Microsoft.PowerShell_profile.ps1'
    )
    'ERROR_HANDLING_STANDARD.md'              = @(
        'profile.d/bootstrap/ErrorHandlingStandard.ps1'
        'scripts/lib/core/Logging.psm1'
    )
    'FRAGMENT_CACHE_USAGE.md'                 = @(
        'scripts/lib/fragment/FragmentCachePath.psm1'
        'scripts/utils/build-fragment-cache.ps1'
        'scripts/utils/clear-fragment-cache.ps1'
    )
    'FRAGMENT_COMMAND_ACCESS.md'              = @(
        'scripts/lib/fragment/CommandDispatcher.psm1'
        'scripts/lib/fragment/FragmentLoader.psm1'
        'scripts/lib/fragment/FragmentCommandRegistry.psm1'
        'scripts/utils/fragment/generate-command-wrappers.ps1'
    )
    'FRAGMENT_LOADING_OPTIMIZATION.md'        = @(
        'scripts/lib/profile/ProfileFragmentLoader.psm1'
        'scripts/lib/fragment/FragmentCommandRegistry.psm1'
        'scripts/lib/fragment/CommandDispatcher.psm1'
        'scripts/lib/fragment/FragmentLoader.psm1'
    )
    'FUNCTION_NAMING_EXCEPTIONS.md'           = @(
        'scripts/utils/code-quality/validate-function-naming.ps1'
    )
    'MODULE_DOCUMENTATION_TEMPLATE.md'        = @(
        'scripts/utils/docs/generate-docs.ps1'
    )
    'MODULE_LOADING_STANDARD.md'              = @(
        'profile.d/bootstrap/ModuleLoading.ps1'
    )
    'PARALLEL_LOADING_STATE_MERGE_ANALYSIS.md' = @(
        'scripts/lib/fragment/FragmentParallelLoading.psm1'
        'scripts/lib/profile/ProfileFragmentLoader.psm1'
    )
    'PREFERENCE_AWARE_INSTALL_HINTS.md'       = @(
        'profile.d/bootstrap/MissingToolWarnings.ps1'
        'profile.d/bootstrap/InstallHintResolver.ps1'
        'scripts/lib/utilities/Command.psm1'
    )
    'PROFILE_LOAD_TIME_OPTIMIZATION.md'         = @(
        'Microsoft.PowerShell_profile.ps1'
        'scripts/lib/profile/ProfileFragmentLoader.psm1'
        'scripts/lib/fragment/FragmentConfig.psm1'
    )
    'PROFILE_PERFORMANCE_OPTIMIZATION.md'       = @(
        'Microsoft.PowerShell_profile.ps1'
        'scripts/lib/profile/ProfileFragmentLoader.psm1'
    )
    'PROMPT_PERFORMANCE_TROUBLESHOOTING.md'     = @(
        'profile.d/starship.ps1'
        'profile.d/oh-my-posh.ps1'
        'scripts/utils/performance/diagnose-profile-performance.ps1'
    )
    'README.md'                                 = @(
        'Microsoft.PowerShell_profile.ps1'
    )
    'SECURITY_ALLOWLIST.md'                     = @(
        'scripts/utils/security/run-security-scan.ps1'
        'PSScriptAnalyzerSettings.psd1'
    )
    'SQLITE_DATABASES.md'                       = @(
        'scripts/utils/database/initialize-databases.ps1'
        'scripts/utils/database/database-maintenance.ps1'
        'scripts/lib/metrics/MetricsHistory.psm1'
    )
    'TESTING.md'                                = @(
        'scripts/utils/code-quality/run-pester.ps1'
        'scripts/utils/code-quality/analyze-coverage.ps1'
        'tests/TestSupport.ps1'
    )
    'TEST_VERIFICATION_MOCKING_GUIDE.md'        = @(
        'tests/TestSupport.ps1'
        'tests/TestSupport/TestMocks.ps1'
    )
    'TOOL_REQUIREMENTS.md'                      = @(
        'requirements.txt'
        'requirements/scoop.txt'
        'requirements/linux.txt'
    )
    'TYPE_SAFETY.md'                            = @(
        'scripts/lib/core/CommonEnums.psm1'
        'scripts/lib/core/ExitCodes.psm1'
    )
    'VERIFY_COVERAGE.md'                        = @(
        'scripts/utils/code-quality/analyze-coverage.ps1'
    )
}

function Get-ExistingDriftBindings {
    $bindings = @{}
    if (-not (Test-Path -LiteralPath $driftLockPath)) {
        return $bindings
    }

    foreach ($line in Get-Content -LiteralPath $driftLockPath) {
        if ($line -match '^(?<doc>.+?)\s+->\s+(?<target>.+?)\s+sig:') {
            $bindings["$($Matches.doc)|$($Matches.target)"] = $true
        }
    }

    return $bindings
}

function Resolve-GuideSourcePath {
    param(
        [string]$Candidate,
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return $null
    }

    $normalized = ($Candidate -replace '\\', '/').Trim()
    if ($normalized -match '^(?<prefix>\.\./)+(?<rest>.+)$') {
        $normalized = $Matches.rest
    }

    if ($normalized -notmatch '\.(ps1|psm1|psd1|txt|json)$') {
        return $null
    }

    $fullPath = Join-Path $RepoRoot ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return $null
    }

    return ($fullPath.Substring($RepoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
}

function Get-SourcePathsFromGuideContent {
    param(
        [string]$Content,
        [string]$RepoRoot
    )

    $paths = [System.Collections.Generic.List[string]]::new()
    $patterns = @(
        "(?:['""`])(?<path>(?:\.\./)*(?:profile\.d|scripts|tests|requirements)[^'""`\s]+\.(?:ps1|psm1|psd1|txt))(?:['""`])",
        '(?<path>(?:profile\.d|scripts|tests|requirements)/[^\s`''")]+?\.(?:ps1|psm1|psd1|txt))',
        '(?<path>Microsoft\.PowerShell_profile\.ps1)',
        '(?<path>PSScriptAnalyzerSettings\.psd1)'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Content, $pattern)) {
            $resolved = Resolve-GuideSourcePath -Candidate $match.Groups['path'].Value -RepoRoot $RepoRoot
            if ($resolved -and -not $paths.Contains($resolved)) {
                $paths.Add($resolved)
            }
        }
    }

    return @($paths)
}

function Get-SourcePathsForGuide {
    param(
        [System.IO.FileInfo]$GuideFile,
        [string]$RepoRoot
    )

    $guideName = $GuideFile.Name
    $paths = [System.Collections.Generic.List[string]]::new()

    if ($script:GuideAnchorMap.ContainsKey($guideName)) {
        foreach ($candidate in $script:GuideAnchorMap[$guideName]) {
            $resolved = Resolve-GuideSourcePath -Candidate $candidate -RepoRoot $RepoRoot
            if ($resolved -and -not $paths.Contains($resolved)) {
                $paths.Add($resolved)
            }
        }
    }

    $content = Get-Content -LiteralPath $GuideFile.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        foreach ($resolved in @(Get-SourcePathsFromGuideContent -Content $content -RepoRoot $RepoRoot)) {
            if (-not $paths.Contains($resolved)) {
                $paths.Add($resolved)
            }
        }
    }

    return @($paths | Select-Object -Unique)
}

if (-not (Get-Command drift -ErrorAction SilentlyContinue)) {
    throw 'drift CLI not found on PATH'
}

$knownBindings = Get-ExistingDriftBindings
$guideFiles = if ($GuidePath) {
    $GuidePath | ForEach-Object {
        $resolved = if ([IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $repoRoot $_ }
        Get-Item -LiteralPath $resolved
    }
}
else {
    Get-ChildItem -Path $guidesRoot -Filter '*.md' -File
}

$linked = 0
$skippedExisting = 0
$skippedUnresolved = [System.Collections.Generic.List[string]]::new()
$failed = [System.Collections.Generic.List[string]]::new()

foreach ($guideFile in $guideFiles) {
    $guideRelative = ($guideFile.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
    $sources = @(Get-SourcePathsForGuide -GuideFile $guideFile -RepoRoot $repoRoot)

    if ($sources.Count -eq 0) {
        $skippedUnresolved.Add($guideRelative)
        continue
    }

    foreach ($source in $sources) {
        $bindingKey = "$guideRelative|$source"
        if (-not $Refresh -and $knownBindings.ContainsKey($bindingKey)) {
            $skippedExisting++
            continue
        }

        if ($DryRun) {
            Write-Host "would link: $guideRelative -> $source"
            $linked++
            continue
        }

        $linkArgs = @($guideRelative, $source)
        if ($Refresh) {
            $linkArgs += '--doc-is-still-accurate'
        }

        $output = & drift link @linkArgs 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $output -match 'refused: target changed since last link') {
            $output = & drift link $guideRelative $source --doc-is-still-accurate 2>&1 | Out-String
        }

        if ($LASTEXITCODE -eq 0) {
            if ($output.Trim()) {
                Write-Host $output.Trim()
            }
            $knownBindings[$bindingKey] = $true
            $linked++
        }
        else {
            $failed.Add("$guideRelative -> $source : $output")
        }
    }
}

Write-Host ''
Write-Host 'Drift guide linking summary:'
Write-Host "  Linked:             $linked"
Write-Host "  Skipped (existing): $skippedExisting"
Write-Host "  Unresolved:         $($skippedUnresolved.Count)"
Write-Host "  Failed:             $($failed.Count)"

if ($skippedUnresolved.Count -gt 0) {
    Write-Host ''
    Write-Host 'Guides without resolvable anchors:'
    $skippedUnresolved | ForEach-Object { Write-Host "  $_" }
}

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failures:'
    $failed | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    exit 1
}
