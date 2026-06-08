<#
.SYNOPSIS
    Links Pester test files to their source targets with drift.

.DESCRIPTION
    Resolves source files for *.tests.ps1 files and runs `drift link` so test
    bindings are recorded in drift.lock. Skips tests whose source cannot be
    resolved confidently.
#>

param(
    [switch]$DryRun,
    [switch]$Refresh,
    [string[]]$TestPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$testsRoot = Join-Path $repoRoot 'tests'
$profileRoot = Join-Path $repoRoot 'profile.d'
$scriptsLibRoot = Join-Path $repoRoot 'scripts' 'lib'
$codeQualityRoot = Join-Path $repoRoot 'scripts' 'utils' 'code-quality'
$driftLockPath = Join-Path $repoRoot 'drift.lock'

function ConvertTo-PascalCase {
    param([string]$KebabName)
    ($KebabName -split '-' | ForEach-Object {
        if ($_.Length -gt 0) { $_.Substring(0, 1).ToUpper() + $_.Substring(1) } else { '' }
    }) -join ''
}

function Get-ExistingDriftBindings {
    $bindings = @{}
    if (-not (Test-Path -LiteralPath $driftLockPath)) {
        return $bindings
    }

    foreach ($line in Get-Content -LiteralPath $driftLockPath) {
        if ($line -match '^(?<test>.+?)\s+->\s+(?<target>.+?)\s+sig:') {
            $bindings["$($Matches.test)|$($Matches.target)"] = $true
        }
    }

    return $bindings
}

function Resolve-SourcePathsFromContent {
    param(
        [string]$Content,
        [string]$RepoRoot
    )

    $paths = [System.Collections.Generic.List[string]]::new()

    function Add-ResolvedPath {
        param([string]$Candidate)
        if ([string]::IsNullOrWhiteSpace($Candidate)) { return }
        $candidate = $Candidate -replace '\\', '/'
        if ($candidate -match '^(?<prefix>\.\./)+(?<rest>.+)$') {
            $candidate = $Matches.rest
        }

        if ($candidate -notmatch '\.(ps1|psm1)$') {
            return
        }

        $fullPath = Join-Path $RepoRoot ($candidate -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            if ($candidate -like 'profile.d/*') {
                $fileName = Split-Path $candidate -Leaf
                $found = Get-ChildItem -Path $profileRoot -Filter $fileName -Recurse -File -ErrorAction SilentlyContinue |
                    Select-Object -First 1
                if ($found) {
                    $fullPath = $found.FullName
                }
                else {
                    return
                }
            }
            else {
                return
            }
        }

        $relative = ($fullPath.Substring($RepoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
        if (-not $paths.Contains($relative)) {
            $paths.Add($relative)
        }
    }

    $patterns = @(
        "(?:['""])(?<path>(?:\.\./)*(?:profile\.d|scripts)[/\\][^'""]+\.(?:ps1|psm1))(?:['""])",
        "(?:['""])(?<path>profile\.d/[^'""]+\.ps1)(?:['""])",
        "Get-TestPath\s+-RelativePath\s+['""](?<path>[^'""]+\.(?:ps1|psm1))['""]",
        "Join-Path\s+\`$script:RepoRoot\s+['""](?<path>[^'""]+)['""]",
        "Join-Path\s+\`$script:TestRepoRoot\s+['""](?<path>[^'""]+)['""]",
        "Join-Path\s+\`$script:TestRepoRoot\s+(?<path>profile\.d/[^\s\)]+\.ps1)",
        "Join-Path\s+\`$script:ProfileDir\s+['""](?<file>[^'""]+\.ps1)['""]",
        "Join-Path\s+\`$repoRoot\s+['""]scripts['""]\s+['""]lib['""]\s+['""](?<segment>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]",
        "Join-Path\s+\`$libPath\s+['""](?<segment>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]",
        "Import-Module\s+\(Join-Path\s+\`$modulePath\s+['""](?<file>[^'""]+\.psm1)['""]\)",
        "Import-Module\s+\(Join-Path\s+\`$libPath\s+['""](?<segment>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]\)",
        "\.\s+\(Join-Path\s+\`$bootstrapDir\s+['""](?<file>[^'""]+\.ps1)['""]\)",
        "Import-Module\s+\(Join-Path\s+\`$libPath\s+['""](?<segment>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]\)",
        "Join-Path\s+\`$script:ProfileDir\s+['""](?<seg1>[^'""]+)['""]\s+['""](?<seg2>[^'""]+)['""]\s+['""](?<file>[^'""]+\.ps1)['""]",
        "Join-Path\s+\`$script:FragmentLibDir\s+['""](?<file>[^'""]+\.psm1)['""]",
        "Join-Path\s+\`$script:ScriptsChecksPath\s+['""](?<file>[^'""]+\.ps1)['""]",
        "Join-Path\s+\`$script:BootstrapDir\s+['""](?<file>[^'""]+\.ps1)['""]",
        "Join-Path\s+\`$script:LibPath\s+['""](?<segment>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]",
        "Join-Path\s+\`$repoRoot\s+['""]scripts['""]\s+['""]utils['""]\s+['""](?<area>[^'""]+)['""]\s+['""](?<subdir>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]",
        "Join-Path\s+\(Join-Path\s+\`$script:ScriptsUtilsPath\s+['""](?<subdir>[^'""]+)['""]\)\s+['""](?<file>[^'""]+\.ps1)['""]",
        "Join-Path\s+\`$script:CodeQualityDir\s+['""](?<file>run-[^'""]+\.ps1)['""]",
        "['""](?<file>document-[^'""]+\.ps1)['""]"
    )

    foreach ($pattern in $patterns) {
        [regex]::Matches($Content, $pattern) | ForEach-Object {
            if ($_.Groups['path'].Success) {
                Add-ResolvedPath -Candidate $_.Groups['path'].Value
            }
            elseif ($_.Groups['file'].Success -and $_.Groups['seg2'].Success) {
                Add-ResolvedPath -Candidate "profile.d/$($_.Groups['seg1'].Value)/$($_.Groups['seg2'].Value)/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $_.Groups['segment'].Success -and $pattern -like '*LibPath*') {
                Add-ResolvedPath -Candidate "scripts/lib/$($_.Groups['segment'].Value)/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $_.Groups['area'].Success) {
                Add-ResolvedPath -Candidate "scripts/utils/$($_.Groups['area'].Value)/$($_.Groups['subdir'].Value)/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $_.Groups['segment'].Success) {
                Add-ResolvedPath -Candidate "scripts/lib/$($_.Groups['segment'].Value)/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $pattern -like '*FragmentLibDir*') {
                Add-ResolvedPath -Candidate "scripts/lib/fragment/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $pattern -like '*ScriptsChecksPath*') {
                Add-ResolvedPath -Candidate "scripts/checks/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $pattern -like '*modulePath*') {
                Add-ResolvedPath -Candidate "scripts/utils/code-quality/modules/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and ($pattern -like '*BootstrapDir*' -or $pattern -like '*bootstrapDir*')) {
                Add-ResolvedPath -Candidate "profile.d/bootstrap/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $_.Groups['subdir'].Success -and $pattern -like '*ScriptsUtilsPath*') {
                Add-ResolvedPath -Candidate "scripts/utils/$($_.Groups['subdir'].Value)/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $pattern -like '*CodeQualityDir*') {
                Add-ResolvedPath -Candidate "scripts/utils/code-quality/$($_.Groups['file'].Value)"
            }
            elseif ($_.Groups['file'].Success -and $pattern -like '*document-*') {
                $found = Get-ChildItem -Path (Join-Path $profileRoot 'conversion-modules' 'document') -Filter $_.Groups['file'].Value -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    Add-ResolvedPath -Candidate (($found.FullName.Substring($RepoRoot.Length)).TrimStart('\', '/').Replace('\', '/'))
                }
            }
            elseif ($_.Groups['file'].Success) {
                Add-ResolvedPath -Candidate "profile.d/$($_.Groups['file'].Value)"
            }
        }
    }

    if ($Content -match 'BootstrapDir|profile\.d\\bootstrap|profile\.d/bootstrap') {
        [regex]::Matches($Content, "['""](?<file>[A-Z][A-Za-z0-9]+\.ps1)['""]") | ForEach-Object {
            $bootstrapFile = Join-Path $profileRoot 'bootstrap' $_.Groups['file'].Value
            if (Test-Path -LiteralPath $bootstrapFile) {
                Add-ResolvedPath -Candidate "profile.d/bootstrap/$($_.Groups['file'].Value)"
            }
        }
    }

    if ($Content -match '\$script:ModulePath\s*=') {
        if ($Content -match "Join-Path\s+\`$repoRoot\s+['""]scripts['""]\s+['""]utils['""]\s+['""](?<area>[^'""]+)['""]\s+['""](?<subdir>[^'""]+)['""]\s+['""](?<file>[^'""]+\.psm1)['""]") {
            Add-ResolvedPath -Candidate "scripts/utils/$($Matches.area)/$($Matches.subdir)/$($Matches.file)"
        }
    }

    return @($paths)
}

function Resolve-ConversionModulePaths {
    param(
        [string]$TestRelativePath
    )

    . (Join-Path $repoRoot 'tests' 'TestSupport' 'TestModuleLoading.ps1')

    $resolved = Resolve-ConversionIntegrationForTest -TestScriptPath $TestRelativePath
    $moduleTypeDir = switch ($resolved.ModuleType) {
        'Documents' { 'document' }
        'Media' { 'media' }
        'Specialized' { 'data/specialized' }
        default { 'data' }
    }

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($moduleName in @($resolved.SelectiveModules)) {
        $searchRoot = Join-Path $profileRoot 'conversion-modules' ($moduleTypeDir -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $searchRoot)) {
            $searchRoot = Join-Path $profileRoot 'conversion-modules'
        }

        $found = Get-ChildItem -Path $searchRoot -Filter $moduleName -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($found) {
            $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) {
                $paths.Add($relative)
            }
        }
    }

    if ($resolved.ContainsKey('AdditionalMediaModules')) {
        foreach ($moduleName in @($resolved.AdditionalMediaModules)) {
            $found = Get-ChildItem -Path (Join-Path $profileRoot 'conversion-modules' 'media') -Filter $moduleName -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) {
                    $paths.Add($relative)
                }
            }
        }
    }

    return @($paths)
}

function Resolve-ProfileExtendedPaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^profile-', '' -replace '-fragment-extended$', '' -replace '-extended$', ''
    $paths = [System.Collections.Generic.List[string]]::new()

    if ($normalized -like 'conversion-data-*' -or $normalized -like 'conversion-*') {
        $conversionTail = $normalized -replace '^conversion-data-', '' -replace '^conversion-', '' -replace '-extended$', ''
        $leafFile = (Split-Path ($conversionTail -replace '-', '/') -Leaf)
        if ($leafFile -and $leafFile -notlike '*.ps1') {
            $leafFile = "$leafFile.ps1"
        }
        $found = Get-ChildItem -Path (Join-Path $profileRoot 'conversion-modules') -Filter $leafFile -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            return @($paths)
        }
    }

    if ($normalized -like 'bootstrap-*') {
        $bootstrapPart = $normalized -replace '^bootstrap-', ''
        $pascal = ConvertTo-PascalCase -KebabName $bootstrapPart
        $bootstrapFile = Join-Path $profileRoot 'bootstrap' "$pascal.ps1"
        if (Test-Path -LiteralPath $bootstrapFile) {
            $paths.Add("profile.d/bootstrap/$pascal.ps1")
            return @($paths)
        }
    }

    if ($normalized -like 'module-loading*') {
        $paths.Add('profile.d/bootstrap/ModuleLoading.ps1')
        return @($paths)
    }

    if ($normalized -match '^(.+)-fragment$') {
        $normalized = $Matches[1]
    }

    $direct = Join-Path $profileRoot "$normalized.ps1"
    if (Test-Path -LiteralPath $direct) {
        $paths.Add("profile.d/$normalized.ps1")
        return @($paths)
    }

    $leafName = Split-Path ($normalized -replace '-', '/') -Leaf
    if (-not $leafName) { $leafName = ($normalized -split '-')[-1] }

    foreach ($segment in @($normalized, ($normalized -replace '-', '-'))) {
        $found = Get-ChildItem -Path $profileRoot -Filter "$segment.ps1" -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($found) {
            $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
        }
    }

    $kebabFile = ($normalized -replace '-', '-') + '.ps1'
    $found = Get-ChildItem -Path $profileRoot -Filter $kebabFile -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) {
        $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
        if (-not $paths.Contains($relative)) { $paths.Add($relative) }
    }

    return @($paths)
}

function Resolve-UtilityScriptPaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^utility-', '' -replace '-extended$', ''
    $paths = [System.Collections.Generic.List[string]]::new()

    $utilityMaps = @{
        'logging'                   = @('scripts/lib/core/Logging.psm1')
        'parallel'                  = @('scripts/lib/parallel/Parallel.psm1')
        'parameters'                = @('scripts/lib/file/FileSystem.psm1', 'scripts/lib/core/ExitCodes.psm1')
        'path-validation'           = @('scripts/lib/path/PathValidation.psm1', 'scripts/lib/file/FileSystem.psm1')
        'docs-generation'           = @('scripts/utils/docs/generate-docs.ps1')
        'script-errors'             = @('scripts/lib/core/ExitCodes.psm1')
        'scripts'                   = @('scripts/lib/ModuleImport.psm1')
    }

    if ($utilityMaps.ContainsKey($normalized)) {
        foreach ($mapped in $utilityMaps[$normalized]) {
            $full = Join-Path $repoRoot ($mapped -replace '/', [IO.Path]::DirectorySeparatorChar)
            if (Test-Path -LiteralPath $full) {
                if (-not $paths.Contains($mapped)) { $paths.Add($mapped) }
            }
        }
        if ($paths.Count -gt 0) { return @($paths) }
    }

    $scriptCandidates = @(
        "scripts/utils/$normalized.ps1",
        "scripts/checks/$normalized.ps1"
    )
    foreach ($candidate in $scriptCandidates) {
        $full = Join-Path $repoRoot ($candidate -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $full) {
            if (-not $paths.Contains($candidate)) { $paths.Add($candidate) }
        }
    }

    $found = Get-ChildItem -Path (Join-Path $repoRoot 'scripts') -Filter "$normalized.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) {
        $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
        if (-not $paths.Contains($relative)) { $paths.Add($relative) }
    }

    return @($paths)
}

function Resolve-ValidationScriptPaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^validation-', '' -replace '-extended$', ''
    $paths = [System.Collections.Generic.List[string]]::new()

    $scriptName = switch -Regex ($normalized) {
        'idempotency' { 'check-idempotency.ps1' }
        'comment-help' { 'check-comment-help.ps1' }
        'commit-messages' { 'check-commit-messages.ps1' }
        'script-standards' { 'check-script-standards.ps1' }
        'validate-profile' { 'validate-profile.ps1' }
        default { "check-$normalized.ps1" }
    }

    $full = Join-Path $repoRoot 'scripts' 'checks' $scriptName
    if (Test-Path -LiteralPath $full) {
        $paths.Add("scripts/checks/$scriptName")
    }

    return @($paths)
}

function Resolve-LibraryModulePaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^library-', '' -replace '-extended$', '' -replace '-additional$', '' -replace '-bootstrap$', ''
    $pascal = ConvertTo-PascalCase -KebabName $normalized

    $candidates = @(
        "$pascal.psm1",
        "$pascal.ps1",
        "$normalized.psm1",
        "$normalized.ps1"
    )

    $explicitMap = @{
        'module-loading'        = @('profile.d/bootstrap/ModuleLoading.ps1')
        'module-loading-additional' = @('profile.d/bootstrap/ModuleLoading.ps1')
        'module-import'         = @('ModuleImport.psm1')
        'tool-wrapper'          = @('../../profile.d/bootstrap/FunctionRegistration.ps1')
        'command'               = @('../../profile.d/bootstrap/CommandCache.ps1')
        'fragment-loading'      = @('fragment/FragmentLoading.psm1')
        'fragment-config'       = @('fragment/FragmentConfig.psm1')
        'fragment-command-registry' = @('fragment/FragmentCommandRegistry.psm1')
        'fragment-loader'           = @('fragment/FragmentLoader.psm1')
        'command-dispatcher'        = @('fragment/CommandDispatcher.psm1')
        'formatting-fallback'       = @('core/Formatting.psm1')
        'python-path'               = @('runtime/Python.psm1')
        'regex-natural-language'    = @('../../profile.d/dev-tools-modules/format/regex.ps1')
        'task-parity-utilities'     = @('../../scripts/utils/task-parity/modules/TaskParityUtilities.psm1')
        'codeanalysis'          = @('code-analysis/TestCoverage.psm1', 'code-analysis/AstParsing.psm1', 'code-analysis/CodeSimilarityDetection.psm1')
        'cloud-provider-missing-warning' = @('runtime/CloudProvider.psm1')
    }

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $explicitMap.Keys) {
        if ($normalized -eq $key -or $normalized -like "*$key*") {
            foreach ($mapped in $explicitMap[$key]) {
                if ($mapped -like '../../*') {
                    $full = Join-Path $repoRoot ($mapped -replace '^\.\./\.\./', '')
                }
                elseif ($mapped -like '../*') {
                    $full = Join-Path $codeQualityRoot ($mapped -replace '^\.\./', '')
                }
                else {
                    $full = Get-ChildItem -Path $scriptsLibRoot -Filter (Split-Path $mapped -Leaf) -Recurse -File -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -like "*$(($mapped -replace '\\', '/'))" } |
                        Select-Object -First 1 |
                        ForEach-Object { $_.FullName }
                }

                if ($full -and (Test-Path -LiteralPath $full)) {
                    $relative = ($full.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                    if (-not $paths.Contains($relative)) { $paths.Add($relative) }
                }
            }
            if ($paths.Count -gt 0) { return @($paths) }
        }
    }

    foreach ($candidate in $candidates) {
        $found = Get-ChildItem -Path $scriptsLibRoot -Filter $candidate -Recurse -File -ErrorAction SilentlyContinue
        foreach ($item in $found) {
            if ($item.Name -like '*.tests.ps1') { continue }
            $relative = ($item.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
        }
    }

    return @($paths)
}

function Resolve-TestRunnerPaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^test-runner-', ''
    $paths = [System.Collections.Generic.List[string]]::new()

    if ($normalized -eq 'run-pester') {
        $paths.Add('scripts/utils/code-quality/run-pester.ps1')
        return @($paths)
    }

    if ($normalized -like 'batch-scripts*') {
        foreach ($name in @('run-unit-batch.ps1', 'run-performance-batch.ps1', 'run-tools-integration-batch.ps1', 'run-conversion-integration-batch.ps1', 'run-conversion-all-batch.ps1')) {
            $full = Join-Path $codeQualityRoot $name
            if (Test-Path -LiteralPath $full) {
                $paths.Add("scripts/utils/code-quality/$name")
            }
        }
        return @($paths)
    }

    $pascal = ConvertTo-PascalCase -KebabName $normalized
    $moduleFile = "$pascal.psm1"
    $found = Get-ChildItem -Path (Join-Path $codeQualityRoot 'modules') -Filter $moduleFile -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $found) {
        $testPrefixed = "Test$pascal.psm1"
        $found = Get-ChildItem -Path (Join-Path $codeQualityRoot 'modules') -Filter $testPrefixed -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }
    if (-not $found) {
        $found = Get-ChildItem -Path (Join-Path $codeQualityRoot 'modules') -Filter "*$pascal*.psm1" -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }
    if ($found) {
        $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
        $paths.Add($relative)
    }

    $scriptFile = "$normalized.ps1"
    $scriptPath = Join-Path $codeQualityRoot $scriptFile
    if (Test-Path -LiteralPath $scriptPath) {
        $paths.Add("scripts/utils/code-quality/$scriptFile")
    }

    return @($paths)
}

function Resolve-TestSupportPaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^test-support-', ''
    $pascal = ConvertTo-PascalCase -KebabName $normalized
    $paths = [System.Collections.Generic.List[string]]::new()

    foreach ($candidate in @("$pascal.ps1", "$normalized.ps1", "Test$pascal.ps1", "TestPaths.ps1")) {
        $full = Join-Path $testsRoot 'TestSupport' $candidate
        if (Test-Path -LiteralPath $full) {
            $relative = ($full.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
        }
    }

    if ($normalized -eq 'paths') {
        $paths.Add('tests/TestSupport/TestPaths.ps1')
    }
    elseif ($normalized -eq 'python-helpers') {
        $paths.Add('tests/TestSupport/TestPythonHelpers.ps1')
    }
    elseif ($normalized -eq 'scoop-helpers') {
        $found = Get-ChildItem -Path (Join-Path $testsRoot 'TestSupport') -Filter '*Scoop*' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
        }
    }

    return @($paths)
}

function Resolve-ProfileFragmentPaths {
    param([string]$BaseName)

    $normalized = $BaseName -replace '^profile-', ''
    $paths = [System.Collections.Generic.List[string]]::new()

    $direct = Join-Path $profileRoot "$normalized.ps1"
    if (Test-Path -LiteralPath $direct) {
        $paths.Add(("profile.d/$normalized.ps1").Replace('\', '/'))
        return @($paths)
    }

    $found = Get-ChildItem -Path $profileRoot -Filter "$normalized.ps1" -Recurse -File -ErrorAction SilentlyContinue
    foreach ($item in $found) {
        $relative = ($item.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
        if (-not $paths.Contains($relative)) { $paths.Add($relative) }
    }

    return @($paths)
}

function Resolve-IntegrationToolPaths {
    param([string]$BaseName)

    $paths = [System.Collections.Generic.List[string]]::new()
    $direct = Join-Path $profileRoot "$BaseName.ps1"
    if (Test-Path -LiteralPath $direct) {
        $paths.Add("profile.d/$BaseName.ps1")
        return @($paths)
    }

    $found = Get-ChildItem -Path $profileRoot -Filter "$BaseName.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) {
        $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
        $paths.Add($relative)
    }

    return @($paths)
}

function Get-SourcePathsForTestFile {
    param(
        [System.IO.FileInfo]$TestFile
    )

    $testRelative = ($TestFile.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
    $baseName = $TestFile.BaseName -replace '\.tests$', ''
    $content = Get-Content -LiteralPath $TestFile.FullName -Raw -ErrorAction SilentlyContinue

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @(Resolve-SourcePathsFromContent -Content $content -RepoRoot $repoRoot)) {
        if (-not $paths.Contains($path)) { $paths.Add($path) }
    }

    if ($testRelative -like 'tests/integration/conversion/data/error-handling/errors*') {
        foreach ($moduleName in @('csv.ps1', 'json.ps1', 'xml.ps1')) {
            $found = Get-ChildItem -Path (Join-Path $profileRoot 'conversion-modules') -Filter $moduleName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/conversion/*') {
        foreach ($path in @(Resolve-ConversionModulePaths -TestRelativePath $testRelative)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/integration/tools/*') {
        foreach ($path in @(Resolve-IntegrationToolPaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/integration/profile/*') {
        $profileMain = Join-Path $repoRoot 'Microsoft.PowerShell_profile.ps1'
        if (Test-Path -LiteralPath $profileMain) {
            if (-not $paths.Contains('Microsoft.PowerShell_profile.ps1')) {
                $paths.Add('Microsoft.PowerShell_profile.ps1')
            }
        }
        foreach ($path in @(Resolve-ProfileFragmentPaths -BaseName ($baseName -replace '^profile-', ''))) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/integration/fragments/*') {
        foreach ($moduleName in @('FragmentCommandRegistry.psm1', 'FragmentLoader.psm1', 'CommandDispatcher.psm1')) {
            $relative = "scripts/lib/fragment/$moduleName"
            if ((Test-Path -LiteralPath (Join-Path $repoRoot ($relative -replace '/', [IO.Path]::DirectorySeparatorChar))) -and -not $paths.Contains($relative)) {
                $paths.Add($relative)
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/filesystem/*') {
        foreach ($moduleName in @('files-listing.ps1', 'files-size.ps1')) {
            $found = Get-ChildItem -Path (Join-Path $profileRoot 'files-modules') -Filter $moduleName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/system/*') {
        foreach ($moduleName in @('utilities-filesystem.ps1', 'utilities-profile.ps1', 'SystemInfo.ps1')) {
            $found = Get-ChildItem -Path $profileRoot -Filter $moduleName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/terminal/history-enhanced-extended*') {
        $found = Get-ChildItem -Path $profileRoot -Filter 'utilities-history-enhanced.ps1' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
        }
    }
    elseif ($testRelative -like 'tests/integration/tools/network/failure*') {
        $found = Get-ChildItem -Path $profileRoot -Filter 'utilities-network.ps1' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
            if (-not $paths.Contains($relative)) { $paths.Add($relative) }
        }
        $failureScript = Join-Path $profileRoot 'utilities-modules' 'network' 'network-failure.ps1'
        if (Test-Path -LiteralPath $failureScript) {
            if (-not $paths.Contains('profile.d/utilities-modules/network/network-failure.ps1')) {
                $paths.Add('profile.d/utilities-modules/network/network-failure.ps1')
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/fragments/generate-command-wrappers*') {
        if (-not $paths.Contains('scripts/utils/fragment/generate-command-wrappers.ps1')) {
            $paths.Add('scripts/utils/fragment/generate-command-wrappers.ps1')
        }
    }
    elseif ($testRelative -like 'tests/integration/test-runner/analyze-coverage*') {
        if (-not $paths.Contains('scripts/utils/code-quality/analyze-coverage.ps1')) {
            $paths.Add('scripts/utils/code-quality/analyze-coverage.ps1')
        }
    }
    elseif ($testRelative -like 'tests/integration/bootstrap/module-loading-standard*') {
        if (-not $paths.Contains('profile.d/bootstrap/ModuleLoading.ps1')) {
            $paths.Add('profile.d/bootstrap/ModuleLoading.ps1')
        }
    }
    elseif ($testRelative -like 'tests/integration/bootstrap/preference-aware-install-hints*') {
        foreach ($hintFile in @('PreferenceAwareInstallHints.ps1', 'InstallHintResolver.ps1', 'EmbeddedInstallHints.ps1')) {
            $found = Get-ChildItem -Path $profileRoot -Filter $hintFile -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/tools/tooling*') {
        foreach ($scriptName in @('generate-docs.ps1', 'spellcheck.ps1')) {
            $full = Get-ChildItem -Path (Join-Path $repoRoot 'scripts') -Filter $scriptName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($full) {
                $relative = ($full.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/validation/*') {
        foreach ($scriptName in @('validate-profile.ps1', 'check-idempotency.ps1', 'check-comment-help.ps1')) {
            $full = Join-Path $repoRoot 'scripts' 'checks' $scriptName
            if (Test-Path -LiteralPath $full) {
                $relative = "scripts/checks/$scriptName"
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/performance/performance*') {
        if (-not $paths.Contains('scripts/utils/code-quality/run-pester.ps1')) {
            $paths.Add('scripts/utils/code-quality/run-pester.ps1')
        }
    }
    elseif ($testRelative -like 'tests/integration/conversion/document/markdown-dialects*' -or
        $testRelative -like 'tests/integration/conversion/document/markdown-notes*') {
        foreach ($moduleName in @('document-markdown-notes.ps1', 'document-markdown.ps1')) {
            $found = Get-ChildItem -Path (Join-Path $profileRoot 'conversion-modules' 'document') -Filter $moduleName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/integration/*') {
        $mirrored = $testRelative -replace '^tests/integration/', 'profile.d/'
        $mirrored = $mirrored -replace '\.tests\.ps1$', '.ps1'
        $full = Join-Path $repoRoot ($mirrored -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $full) {
            if (-not $paths.Contains($mirrored)) { $paths.Add($mirrored) }
        }
        else {
            $found = Get-ChildItem -Path $profileRoot -Filter "$(Split-Path $mirrored -Leaf)" -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) {
                $relative = ($found.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
                if (-not $paths.Contains($relative)) { $paths.Add($relative) }
            }
        }
    }
    elseif ($testRelative -like 'tests/unit/library-*') {
        foreach ($path in @(Resolve-LibraryModulePaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/unit/profile-*') {
        foreach ($path in @(Resolve-ProfileExtendedPaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
        if ($paths.Count -eq 0) {
            foreach ($path in @(Resolve-ProfileFragmentPaths -BaseName $baseName)) {
                if (-not $paths.Contains($path)) { $paths.Add($path) }
            }
        }
    }
    elseif ($testRelative -like 'tests/unit/utility-*') {
        foreach ($path in @(Resolve-UtilityScriptPaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/unit/validation-*') {
        foreach ($path in @(Resolve-ValidationScriptPaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/unit/test-runner-*') {
        foreach ($path in @(Resolve-TestRunnerPaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/unit/test-support-*') {
        foreach ($path in @(Resolve-TestSupportPaths -BaseName $baseName)) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    elseif ($testRelative -like 'tests/performance/*') {
        foreach ($path in @(Resolve-IntegrationToolPaths -BaseName ($baseName -replace '-performance$', ''))) {
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }

    return @($paths | Where-Object {
        $_ -and $_ -notmatch '\.tests\.ps1$' -and $_ -notlike 'tests/TestSupport.ps1' -and $_ -match '\.(ps1|psm1)$'
    } | Select-Object -Unique)
}

if (-not (Get-Command drift -ErrorAction SilentlyContinue)) {
    throw 'drift CLI not found on PATH'
}

$knownBindings = Get-ExistingDriftBindings
$testFiles = if ($TestPath) {
    $TestPath | ForEach-Object {
        $resolved = if ([IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $repoRoot $_ }
        Get-Item -LiteralPath $resolved
    }
}
else {
    Get-ChildItem -Path $testsRoot -Filter '*.tests.ps1' -Recurse -File
}

$linked = 0
$skippedExisting = 0
$skippedUnresolved = [System.Collections.Generic.List[string]]::new()
$failed = [System.Collections.Generic.List[string]]::new()

foreach ($testFile in $testFiles) {
    $testRelative = ($testFile.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
    $sources = @(Get-SourcePathsForTestFile -TestFile $testFile)

    if ($sources.Count -eq 0) {
        $skippedUnresolved.Add($testRelative)
        continue
    }

    foreach ($source in $sources) {
        $bindingKey = "$testRelative|$source"
        if (-not $Refresh -and $knownBindings.ContainsKey($bindingKey)) {
            $skippedExisting++
            continue
        }

        if ($DryRun) {
            Write-Host "would link: $testRelative -> $source"
            $linked++
            continue
        }

        $linkArgs = @($testRelative, $source)
        if ($Refresh) {
            $linkArgs += '--doc-is-still-accurate'
        }

        $output = & drift link @linkArgs 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $output -match 'refused: target changed since last link') {
            $output = & drift link $testRelative $source --doc-is-still-accurate 2>&1 | Out-String
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host $output.Trim()
            $knownBindings[$bindingKey] = $true
            $linked++
        }
        else {
            $failed.Add("$testRelative -> $source : $output")
        }
    }
}

Write-Host ''
Write-Host "Drift test linking summary:"
Write-Host "  Linked:             $linked"
Write-Host "  Skipped (existing): $skippedExisting"
Write-Host "  Unresolved:         $($skippedUnresolved.Count)"
Write-Host "  Failed:             $($failed.Count)"

if ($skippedUnresolved.Count -gt 0 -and $skippedUnresolved.Count -le 30) {
    Write-Host ''
    Write-Host 'Unresolved tests:'
    $skippedUnresolved | ForEach-Object { Write-Host "  $_" }
}
elseif ($skippedUnresolved.Count -gt 30) {
    Write-Host ''
    Write-Host "First 30 unresolved tests:"
    $skippedUnresolved | Select-Object -First 30 | ForEach-Object { Write-Host "  $_" }
}

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failures:'
    $failed | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    exit 1
}
