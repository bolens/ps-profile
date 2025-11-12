<#
scripts/utils/run_pester.ps1

.SYNOPSIS
    Runs Pester tests for the PowerShell profile.

.DESCRIPTION
    Ensures Pester is available and runs the test suite in this repository. Can run all tests
    or a specific test file. Optionally includes code coverage reporting.

.PARAMETER TestFile
    Optional path to a specific test file to run. If not specified, runs all tests in the
    tests directory.

.PARAMETER Coverage
    If specified, enables code coverage reporting for profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run_pester.ps1

    Runs all Pester tests in the tests directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run_pester.ps1 -TestFile tests\profile.tests.ps1

    Runs only the profile.tests.ps1 test file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run_pester.ps1 -Coverage

    Runs all tests with code coverage reporting enabled.
#>

param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Test file or directory does not exist: $_"
            }
            $true
        })]
    [string]$TestFile = "",

    [ValidateSet('All', 'Unit', 'Integration', 'Performance')]
    [string]$Suite = 'All',

    [switch]$Coverage
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $testsDir = Join-Path $repoRoot 'tests'
    $profileDir = Join-Path $repoRoot 'profile.d'
    $testSupportPath = Join-Path $testsDir 'TestSupport.ps1'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

if (-not (Test-Path -LiteralPath $testSupportPath)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Test support script not found at $testSupportPath"
}

. $testSupportPath

$repoRootFullPath = [System.IO.Path]::GetFullPath($repoRoot)
$repoRootPattern = [regex]::Escape($repoRootFullPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))

<#
.SYNOPSIS
    Converts an arbitrary path to a repository-relative representation.
.DESCRIPTION
    Resolves the supplied path, and when it resides within the current repository
    root, returns the relative path. Paths outside the repository (or those that
    cannot be resolved) are returned unchanged.
.PARAMETER PathString
    The candidate path or text to convert.
.OUTPUTS
    System.String
#>
function ConvertTo-RepoRelativePath {
    param([string]$PathString)

    if ([string]::IsNullOrWhiteSpace($PathString)) {
        return $PathString
    }

    $candidate = $PathString
    try {
        $candidate = (Resolve-Path -Path $PathString -ErrorAction Stop).ProviderPath
    }
    catch {
        $candidate = $PathString
    }

    $relative = [System.IO.Path]::GetRelativePath($repoRootFullPath, $candidate)

    if (-not [System.IO.Path]::IsPathRooted($relative)) {
        return $relative
    }

    return $PathString
}

<#
.SYNOPSIS
    Sanitizes test runner output by replacing repository roots with relative paths.
.DESCRIPTION
    Rewrites occurrences of the repository root (with either separator style) and
    any quoted paths within a text line, returning an updated string without
    sensitive absolute information.
.PARAMETER Text
    The text to inspect and rewrite.
.OUTPUTS
    System.String
#>
function Convert-TestOutputLine {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    $converted = [string]$Text

    if ($repoRootPattern) {
        $converted = [System.Text.RegularExpressions.Regex]::Replace(
            $converted,
            "${repoRootPattern}(?:[\\/]+)",
            '',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        $converted = [System.Text.RegularExpressions.Regex]::Replace(
            $converted,
            $repoRootPattern,
            '.',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }

    $converted = [System.Text.RegularExpressions.Regex]::Replace(
        $converted,
        "'([^']+)'",
        {
            param($match)
            $candidate = $match.Groups[1].Value
            $relative = ConvertTo-RepoRelativePath -PathString $candidate
            if ($relative -ne $candidate) {
                return "'$relative'"
            }
            return $match.Value
        },
        [System.Text.RegularExpressions.RegexOptions]::None
    )

    return $converted
}

$script:OriginalWriteHostScriptBlock = $null
$script:OriginalWriteWarningScriptBlock = $null
$script:WriteWarningOverrideActive = $false
$script:EmittedWarningMessages = $null

<#
.SYNOPSIS
    Starts intercepting Write-Host output to sanitize test runner messages.
.DESCRIPTION
    Temporarily replaces Write-Host with a wrapper that rewrites absolute repository
    paths before delegating to the original implementation. Subsequent calls are
    ignored until Stop-TestOutputInterceptor is invoked.
#>
function Start-TestOutputInterceptor {
    if ($script:OriginalWriteHostScriptBlock -or $script:WriteHostOverrideActive) {
        return
    }

    $script:OriginalWriteHostScriptBlock = $null
    $script:WriteHostOverrideActive = $false
    $script:OriginalWriteWarningScriptBlock = $null
    $script:WriteWarningOverrideActive = $false
    $script:EmittedWarningMessages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $command = Get-Command -Name Write-Host -ErrorAction Stop
        if ($command.CommandType -eq 'Function') {
            $script:OriginalWriteHostScriptBlock = $command.ScriptBlock
        }
    }
    catch {
        return
    }

    <#
    .SYNOPSIS
        Overrides Write-Host to sanitize emitted repository paths.
    .DESCRIPTION
        Invoked while tests run to rewrite any absolute repository paths to
        relative equivalents before delegating to the original Write-Host
        implementation.
    #>
    function global:RunPester_WriteHostOverride {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
            [object[]]$Object,
            [ConsoleColor]$ForegroundColor,
            [ConsoleColor]$BackgroundColor,
            [switch]$NoNewLine,
            [object]$Separator = ' '
        )

        $processedObject = $Object
        if ($processedObject) {
            $processedObject = foreach ($item in $processedObject) {
                if ($item -is [string]) { Convert-TestOutputLine -Text $item } else { $item }
            }
        }

        $arguments = @{}
        foreach ($entry in $PSBoundParameters.GetEnumerator()) {
            if ($entry.Key -eq 'Object') {
                $arguments[$entry.Key] = $processedObject
            }
            else {
                $arguments[$entry.Key] = $entry.Value
            }
        }

        if (-not $arguments.ContainsKey('Object')) {
            $arguments['Object'] = $processedObject
        }

        Microsoft.PowerShell.Utility\Write-Host @arguments
    }

    Set-Item -Path Function:\Write-Host -Value ${function:RunPester_WriteHostOverride} -Force
    $script:WriteHostOverrideActive = $true

    try {
        $warningCommand = Get-Command -Name Write-Warning -ErrorAction Stop
        if ($warningCommand.CommandType -eq 'Function') {
            $script:OriginalWriteWarningScriptBlock = $warningCommand.ScriptBlock
        }
    }
    catch {
    }

    <#
    .SYNOPSIS
        Overrides Write-Warning to deduplicate and sanitize messages.
    .DESCRIPTION
        Ensures noisy warnings only appear once per unique message while still
        passing through repository path sanitation.
    #>
    function global:RunPester_WriteWarningOverride {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [object]$Message
        )

        process {
            $text = if ($null -ne $Message) { [string]$Message } else { [string]::Empty }
            $converted = Convert-TestOutputLine -Text $text
            if ([string]::IsNullOrWhiteSpace($converted)) {
                $converted = $text
            }

            if (-not $script:EmittedWarningMessages) {
                $script:EmittedWarningMessages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }

            if ($script:EmittedWarningMessages.Add($converted)) {
                $arguments = @{}
                foreach ($entry in $PSBoundParameters.GetEnumerator()) {
                    if ($entry.Key -eq 'Message') {
                        $arguments[$entry.Key] = $converted
                    }
                    else {
                        $arguments[$entry.Key] = $entry.Value
                    }
                }

                if (-not $arguments.ContainsKey('Message')) {
                    $arguments['Message'] = $converted
                }

                if ($script:OriginalWriteWarningScriptBlock) {
                    & $script:OriginalWriteWarningScriptBlock @arguments
                }
                else {
                    Microsoft.PowerShell.Utility\Write-Warning @arguments
                }
            }
        }
    }

    Set-Item -Path Function:\Write-Warning -Value ${function:RunPester_WriteWarningOverride} -Force
    $script:WriteWarningOverrideActive = $true
}

<#
.SYNOPSIS
    Restores the original Write-Host implementation after interception.
.DESCRIPTION
    Replaces the temporary wrapper installed by Start-TestOutputInterceptor with the
    previously captured Write-Host script block. Subsequent calls are ignored once the
    original function has been restored.
#>
function Stop-TestOutputInterceptor {
    if (-not $script:WriteHostOverrideActive) {
        if (-not $script:WriteWarningOverrideActive) {
            return
        }
    }

    if ($script:WriteHostOverrideActive) {
        if ($script:OriginalWriteHostScriptBlock) {
            Set-Item -Path Function:\Write-Host -Value $script:OriginalWriteHostScriptBlock -Force
        }
        else {
            Remove-Item -Path Function:\Write-Host -Force -ErrorAction SilentlyContinue
        }

        Remove-Item -Path Function:\RunPester_WriteHostOverride -Force -ErrorAction SilentlyContinue
        $script:OriginalWriteHostScriptBlock = $null
        $script:WriteHostOverrideActive = $false
    }

    if ($script:WriteWarningOverrideActive) {
        if ($script:OriginalWriteWarningScriptBlock) {
            Set-Item -Path Function:\Write-Warning -Value $script:OriginalWriteWarningScriptBlock -Force
        }
        else {
            Remove-Item -Path Function:\Write-Warning -Force -ErrorAction SilentlyContinue
        }

        Remove-Item -Path Function:\RunPester_WriteWarningOverride -Force -ErrorAction SilentlyContinue
        $script:OriginalWriteWarningScriptBlock = $null
        $script:WriteWarningOverrideActive = $false
        $script:EmittedWarningMessages = $null
    }
}

function ConvertTo-RepoRelativePath {
    param([string]$PathString)

    if ([string]::IsNullOrWhiteSpace($PathString)) {
        return $PathString
    }

    $candidate = $PathString
    try {
        $candidate = (Resolve-Path -Path $PathString -ErrorAction Stop).ProviderPath
    }
    catch {
        $candidate = $PathString
    }

    $relative = [System.IO.Path]::GetRelativePath($repoRootFullPath, $candidate)

    if (-not [System.IO.Path]::IsPathRooted($relative)) {
        return $relative
    }

    return $PathString
}

# Ensure Pester 5+ is available and imported
$requiredPesterVersion = [version]'5.0.0'

try {
    Ensure-ModuleAvailable -ModuleName 'Pester'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$installedPester = Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1
if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    try {
        Write-ScriptMessage -Message "Installing Pester $requiredPesterVersion or newer"
        Install-RequiredModule -ModuleName 'Pester' -Scope 'CurrentUser' -Force
        $installedPester = Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    $message = "Pester $requiredPesterVersion or newer is required but could not be installed."
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $message
}

try {
    Import-Module -Name 'Pester' -MinimumVersion $requiredPesterVersion -Force -ErrorAction Stop
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Using Pester v$($installedPester.Version)"

$config = New-PesterConfiguration
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.Output.Verbosity = 'Detailed'

if ([string]::IsNullOrWhiteSpace($TestFile)) {
    switch ($Suite) {
        'Unit' {
            $suiteFiles = Get-TestSuiteFiles -Suite 'Unit' -StartPath $repoRoot
        }
        'Integration' {
            $suiteFiles = Get-TestSuiteFiles -Suite 'Integration' -StartPath $repoRoot
        }
        'Performance' {
            $suiteFiles = Get-TestSuiteFiles -Suite 'Performance' -StartPath $repoRoot
        }
        default {
            $suiteFiles = @()
            foreach ($s in 'Unit', 'Integration', 'Performance') {
                $suiteFiles += Get-TestSuiteFiles -Suite $s -StartPath $repoRoot
            }
        }
    }

    $files = $suiteFiles | Select-Object -ExpandProperty FullName -Unique
    $relativeFiles = $files | ForEach-Object { ConvertTo-RepoRelativePath $_ }

    if (-not $files) {
        $messageTarget = if ($Suite -eq 'All') { $testsDir } else { Get-TestSuitePath -Suite $Suite -StartPath $repoRoot }
        $relativeTarget = ConvertTo-RepoRelativePath $messageTarget
        Write-ScriptMessage -Message "No test files found for suite '$Suite' under $relativeTarget" -LogLevel 'Warning'
    }
    else {
        $suiteLabel = if ($Suite -eq 'All') { 'all suites' } else { "suite '$Suite'" }
        $fileList = $relativeFiles -join ', '
        Write-ScriptMessage -Message ("Running Pester tests for {0}: {1}" -f $suiteLabel, $fileList)
    }

    $config.Run.Path = if ($relativeFiles) { $relativeFiles } else { @('tests') }
}
else {
    if ($Suite -ne 'All') {
        Write-ScriptMessage -Message "TestFile parameter specified; overriding Suite '$Suite'" -LogLevel 'Warning'
    }

    $resolvedTestPath = (Resolve-Path -Path $TestFile).ProviderPath

    if (Test-Path -LiteralPath $resolvedTestPath -PathType Container) {
        $testScripts = Get-PowerShellScripts -Path $resolvedTestPath -Recurse -SortByName |
        Where-Object { $_.Name -like '*.tests.ps1' }
        $files = $testScripts | Select-Object -ExpandProperty FullName
        if (-not $files) {
            $relativeDirectory = ConvertTo-RepoRelativePath $resolvedTestPath
            Write-ScriptMessage -Message "No test files found under $relativeDirectory" -LogLevel 'Warning'
            $config.Run.Path = @($relativeDirectory)
        }
        else {
            $relativeFiles = $files | ForEach-Object { ConvertTo-RepoRelativePath $_ }
            Write-ScriptMessage -Message "Running Pester tests: $($relativeFiles -join ', ')"
            $config.Run.Path = $relativeFiles
        }
    }
    else {
        $relativePath = ConvertTo-RepoRelativePath $resolvedTestPath
        Write-ScriptMessage -Message "Running Pester tests: $relativePath"
        $config.Run.Path = @($relativePath)
    }
}

if ($Coverage) {
    $coverageDir = Join-Path $repoRoot 'scripts' 'data'
    if (-not (Test-Path -LiteralPath $coverageDir)) {
        New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
    }

    $coverageFile = Join-Path $coverageDir 'coverage.xml'

    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.OutputPath = $coverageFile
    $config.CodeCoverage.Path = @($profileDir)
    $config.CodeCoverage.RecursePaths = $true

    Write-ScriptMessage -Message "Code coverage enabled for: $(ConvertTo-RepoRelativePath $profileDir)"
    Write-ScriptMessage -Message "Coverage report: $(ConvertTo-RepoRelativePath $coverageFile)"
}
else {
    $config.CodeCoverage.Enabled = $false
}

Push-Location -LiteralPath $repoRoot
Start-TestOutputInterceptor
try {
    $result = Invoke-Pester -Configuration $config
}
finally {
    Stop-TestOutputInterceptor
    Pop-Location
}

$result

