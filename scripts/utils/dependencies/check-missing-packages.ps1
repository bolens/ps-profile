<#
scripts/utils/dependencies/check-missing-packages.ps1

.SYNOPSIS
    Checks for missing npm, Python, and system packages required for data format conversions and tools.

.DESCRIPTION
    Loads package lists from requirements.txt, requirements/scoop.txt, requirements/linux.txt,
    and package.json, then checks whether they are installed. Reports missing packages with
    installation instructions for the detected package manager (Scoop, apt, pacman, or dnf).

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-missing-packages.ps1

    Checks all required packages and reports which are missing.

.NOTES
    Package lists:
    - npm: package.json dependencies
    - Python: requirements.txt
    - Windows: requirements/scoop.txt (Scoop)
    - Linux: requirements/linux.txt (apt, pacman, or dnf section)

    Override system package manager: $env:PS_SYSTEM_PACKAGE_MANAGER = 'apt' | 'pacman' | 'dnf' | 'scoop'

    Exit Codes:
    - 0 (EXIT_SUCCESS): All packages are installed
    - 1 (EXIT_VALIDATION_FAILURE): Some packages are missing
#>

# Import ModuleImport first (bootstrap)
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug enabled
}

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'RequirementsList' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    if (-not $repoRoot) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to determine repository root from script path: $PSScriptRoot"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$testSupportDir = Join-Path $repoRoot 'tests' 'TestSupport'
if ($testSupportDir -and (Test-Path -LiteralPath $testSupportDir)) {
    $env:TERM = 'xterm-256color'
    $helperScripts = @(
        'TestNpmHelpers.ps1',
        'TestPythonHelpers.ps1',
        'TestScoopHelpers.ps1',
        'TestLinuxPackageHelpers.ps1'
    )
    foreach ($helperScript in $helperScripts) {
        $helperPath = Join-Path $testSupportDir $helperScript
        if (Test-Path -LiteralPath $helperPath) {
            . $helperPath
        }
    }
}
else {
    Write-ScriptMessage -Message "Warning: TestSupport helpers not found, package checking may be limited" -Level Warning
}

try {
    $packageJsonPath = Join-Path $repoRoot 'package.json'
    $npmPackages = Get-NpmRequirementsFromPackageJson -Path $packageJsonPath
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to load npm packages from package.json: $($_.Exception.Message)"
}

try {
    $pythonRequirementsPath = Get-RequirementsManifestPath -RepoRoot $repoRoot -Kind 'python'
    $pythonPackages = Get-PythonRequirementsFromFile -Path $pythonRequirementsPath
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to load Python packages from requirements.txt: $($_.Exception.Message)"
}

$systemPackageManager = Get-SystemPackageManagerKind
$systemPackages = @()
if ($systemPackageManager -in 'scoop', 'apt', 'pacman', 'dnf') {
    try {
        $systemPackages = Get-SystemRequirementsPackages -RepoRoot $repoRoot -PackageManager $systemPackageManager
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to load system packages: $($_.Exception.Message)"
    }
}

$missingNpm = @()
$missingPython = @()
$missingSystem = @()
$npmCheckDuration = 0
$pythonCheckDuration = 0
$systemCheckDuration = 0

Write-ScriptMessage -Message "Checking npm/pnpm packages ($($npmPackages.Count) from package.json)..." -LogLevel Info
$npmCheckStartTime = Get-Date
$npmCheckErrors = [System.Collections.Generic.List[string]]::new()
foreach ($pkg in $npmPackages) {
    try {
        if (Get-Command Test-NpmPackageAvailable -ErrorAction SilentlyContinue) {
            if (Test-NpmPackageAvailable -PackageName $pkg -ErrorAction Stop) {
                Write-ScriptMessage -Message "  ✓ $pkg" -ForegroundColor Green
            }
            else {
                Write-ScriptMessage -Message "  ✗ $pkg" -ForegroundColor Red
                $missingNpm += $pkg
            }
        }
        else {
            Write-ScriptMessage -Message "  ? $pkg (cannot check - Test-NpmPackageAvailable not available)" -IsWarning
        }
    }
    catch {
        $npmCheckErrors.Add($pkg)
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to check npm package" -OperationName 'dependencies.check-npm' -Context @{
                package_name = $pkg
            } -Code 'NpmPackageCheckFailed'
        }
        else {
            Write-ScriptMessage -Message "  ✗ $pkg (error checking)" -IsWarning
        }
        $missingNpm += $pkg
    }
}
$npmCheckDuration = ((Get-Date) - $npmCheckStartTime).TotalMilliseconds

if ($debugLevel -ge 2) {
    Write-Verbose "[dependencies.check-packages] npm check completed in ${npmCheckDuration}ms"
    Write-Verbose "[dependencies.check-packages] npm missing: $($missingNpm.Count), Errors: $($npmCheckErrors.Count)"
}

if ($npmCheckErrors.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some npm package checks failed" -OperationName 'dependencies.check-npm' -Context @{
            failed_packages = $npmCheckErrors -join ','
            failed_count    = $npmCheckErrors.Count
        } -Code 'NpmPackageCheckPartialFailure'
    }
}

Write-ScriptMessage -Message "Checking Python packages ($($pythonPackages.Count) from requirements.txt)..." -LogLevel Info

if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-packages] Starting Python package check"
}

$venvPython = $null
$venvPath = Join-Path $repoRoot '.venv'
if ($venvPath -and (Test-Path -LiteralPath $venvPath)) {
    $venvPythonPath = Join-Path $venvPath 'Scripts' 'python.exe'
    if ($venvPythonPath -and (Test-Path -LiteralPath $venvPythonPath)) {
        $venvPython = $venvPythonPath
        Write-ScriptMessage -Message "  Using virtual environment: $venvPath" -LogLevel Debug
    }
    else {
        $venvPythonPath = Join-Path $venvPath 'bin' 'python'
        if ($venvPythonPath -and (Test-Path -LiteralPath $venvPythonPath)) {
            $venvPython = $venvPythonPath
            Write-ScriptMessage -Message "  Using virtual environment: $venvPath" -LogLevel Debug
        }
    }
}

$pythonCheckStartTime = Get-Date
foreach ($pkg in $pythonPackages) {
    if (Get-Command Test-PythonPackageAvailable -ErrorAction SilentlyContinue) {
        if (Test-PythonPackageAvailable -PackageName $pkg) {
            Write-ScriptMessage -Message "  ✓ $pkg" -ForegroundColor Green
        }
        else {
            Write-ScriptMessage -Message "  ✗ $pkg" -ForegroundColor Red
            $missingPython += $pkg
        }
        continue
    }

    $pythonCmd = $null
    if ($venvPython) {
        $pythonCmd = $venvPython
    }
    elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = 'python'
    }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = 'python3'
    }

    if (-not $pythonCmd) {
        Write-ScriptMessage -Message "  ✗ Python not available" -IsError
        $missingPython = $pythonPackages
        break
    }

    $checkScript = "import sys; import importlib.util; spec = importlib.util.find_spec('$pkg'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path ([IO.Path]::GetTempPath()) "python-check-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkScript -Encoding UTF8
    try {
        & $pythonCmd $tempCheck 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-ScriptMessage -Message "  ✓ $pkg" -ForegroundColor Green
        }
        else {
            Write-ScriptMessage -Message "  ✗ $pkg" -ForegroundColor Red
            $missingPython += $pkg
        }
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to check Python package" -OperationName 'dependencies.check-python' -Context @{
                package_name = $pkg
            } -Code 'PythonPackageCheckFailed'
        }
        else {
            Write-ScriptMessage -Message "  ✗ $pkg (error checking)" -IsError
        }
        $missingPython += $pkg
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
}
$pythonCheckDuration = ((Get-Date) - $pythonCheckStartTime).TotalMilliseconds

if ($debugLevel -ge 2) {
    Write-Verbose "[dependencies.check-packages] Python check completed in ${pythonCheckDuration}ms"
    Write-Verbose "[dependencies.check-packages] Python missing: $($missingPython.Count)"
}

if (-not $systemPackageManager) {
    Write-ScriptMessage -Message "Skipping system package check (no supported package manager detected)" -IsWarning
}
elseif ($systemPackages.Count -eq 0) {
    Write-ScriptMessage -Message "Skipping system package check (no packages listed for $systemPackageManager)" -IsWarning
}
else {
    $requirementsFile = if ($systemPackageManager -eq 'scoop') {
        'requirements/scoop.txt'
    }
    else {
        "requirements/linux.txt ($systemPackageManager section)"
    }

    Write-ScriptMessage -Message "Checking system packages ($($systemPackages.Count) from $requirementsFile via $systemPackageManager)..." -LogLevel Info

    if ($debugLevel -ge 1) {
        Write-Verbose "[dependencies.check-packages] Starting system package check ($systemPackageManager)"
    }

    $systemCheckStartTime = Get-Date
    $systemCheckErrors = [System.Collections.Generic.List[string]]::new()

    if ($systemPackageManager -eq 'scoop' -and -not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-ScriptMessage -Message "  ✗ Scoop is not installed - cannot check Scoop packages" -IsWarning
        Write-ScriptMessage -Message "  Install Scoop from: https://scoop.sh/" -LogLevel Info
        $missingSystem = $systemPackages
    }
    else {
        if ($systemPackageManager -eq 'scoop') {
            $scoopDetectionPath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'ScoopDetection.psm1'
            if ($scoopDetectionPath -and (Test-Path -LiteralPath $scoopDetectionPath)) {
                Import-Module $scoopDetectionPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
        }

        foreach ($pkg in $systemPackages) {
            try {
                $installed = $false
                if ($systemPackageManager -eq 'scoop') {
                    if (Get-Command Test-ScoopPackageAvailable -ErrorAction SilentlyContinue) {
                        $installed = Test-ScoopPackageAvailable -PackageName $pkg -ErrorAction Stop
                    }
                    else {
                        $scoopList = & scoop list $pkg 2>&1 -ErrorAction Stop
                        $installed = ($LASTEXITCODE -eq 0 -and $scoopList -match $pkg)
                    }
                }
                elseif (Get-Command Test-LinuxSystemPackageAvailable -ErrorAction SilentlyContinue) {
                    $installed = Test-LinuxSystemPackageAvailable -PackageName $pkg -PackageManager $systemPackageManager -ErrorAction Stop
                }

                if ($installed) {
                    Write-ScriptMessage -Message "  ✓ $pkg" -ForegroundColor Green
                }
                else {
                    Write-ScriptMessage -Message "  ✗ $pkg" -ForegroundColor Red
                    $missingSystem += $pkg
                }
            }
            catch {
                $systemCheckErrors.Add($pkg)
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to check system package" -OperationName 'dependencies.check-system' -Context @{
                        package_name     = $pkg
                        package_manager  = $systemPackageManager
                    } -Code 'SystemPackageCheckFailed'
                }
                else {
                    Write-ScriptMessage -Message "  ? $pkg (error checking)" -IsWarning
                }
                $missingSystem += $pkg
            }
        }

        if ($systemCheckErrors.Count -gt 0) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Some system package checks failed" -OperationName 'dependencies.check-system' -Context @{
                    failed_packages = $systemCheckErrors -join ','
                    failed_count    = $systemCheckErrors.Count
                } -Code 'SystemPackageCheckPartialFailure'
            }
        }
    }

    $systemCheckDuration = ((Get-Date) - $systemCheckStartTime).TotalMilliseconds

    if ($debugLevel -ge 2) {
        Write-Verbose "[dependencies.check-packages] System check completed in ${systemCheckDuration}ms"
        Write-Verbose "[dependencies.check-packages] System missing: $($missingSystem.Count), Errors: $($systemCheckErrors.Count)"
    }
}

if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-packages] Generating package check summary"
}

if ($debugLevel -ge 3) {
    $totalCheckDuration = $npmCheckDuration + $pythonCheckDuration + $systemCheckDuration
    Write-Host "  [dependencies.check-packages] Performance - npm: ${npmCheckDuration}ms, Python: ${pythonCheckDuration}ms, System: ${systemCheckDuration}ms, Total: ${totalCheckDuration}ms" -ForegroundColor DarkGray
}

Write-ScriptMessage -Message ("=" * 60) -LogLevel Info
if ($missingNpm.Count -eq 0 -and $missingPython.Count -eq 0 -and $missingSystem.Count -eq 0) {
    Write-ScriptMessage -Message "All packages are installed!" -ForegroundColor Green
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

if ($missingNpm.Count -gt 0) {
    Write-ScriptMessage -Message "Missing npm/pnpm packages:" -IsWarning
    $missingNpm | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }
    $packageJsonFile = Join-Path $repoRoot 'package.json'
    if ($packageJsonFile -and (Test-Path -LiteralPath $packageJsonFile)) {
        Write-ScriptMessage -Message "Install with: pnpm add -g $($missingNpm -join ' ')" -LogLevel Info
        Write-ScriptMessage -Message "Or use: pnpm run install-js-global (from project root)" -LogLevel Info
    }
    else {
        Write-ScriptMessage -Message "Install with: pnpm add -g $($missingNpm -join ' ')" -LogLevel Info
    }
}

if ($missingPython.Count -gt 0) {
    Write-ScriptMessage -Message "Missing Python packages:" -IsWarning
    $missingPython | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }

    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        try {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'python-package' -ToolType 'python-package' -DefaultInstallCommand "pip install $($missingPython[0])"
            if ($hint -match '^Install with:\s*(.+)$') {
                $Matches[1] -replace '\{package\}', $missingPython[0]
            }
            else {
                "pip install $($missingPython -join ' ')"
            }
        }
        catch {
            "pip install $($missingPython -join ' ')"
        }
    }
    else {
        "pip install $($missingPython -join ' ')"
    }

    $requirementsFile = Get-RequirementsManifestPath -RepoRoot $repoRoot -Kind 'python'
    if (Test-Path -LiteralPath $requirementsFile) {
        $reqInstallHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            try {
                $hint = Get-PreferenceAwareInstallHint -ToolName 'requirements' -ToolType 'python-package' -DefaultInstallCommand 'pip install -r requirements.txt'
                if ($hint -match '^Install with:\s*(.+)$') {
                    $Matches[1] -replace '-r requirements\.txt', '-r requirements.txt'
                }
                else {
                    'uv pip install -r requirements.txt'
                }
            }
            catch {
                'uv pip install -r requirements.txt'
            }
        }
        else {
            'uv pip install -r requirements.txt'
        }
        Write-ScriptMessage -Message "Install with: $reqInstallHint" -LogLevel Info
        Write-ScriptMessage -Message "Or install individually: $installHint" -LogLevel Info
    }
    else {
        Write-ScriptMessage -Message "Install with: $installHint" -LogLevel Info
    }
}

if ($missingSystem.Count -gt 0 -and $systemPackageManager) {
    Write-ScriptMessage -Message "Missing system packages ($systemPackageManager):" -IsWarning
    $missingSystem | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }

    $bulkInstall = Get-SystemPackageInstallCommand -PackageNames $missingSystem -PackageManager $systemPackageManager

    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        try {
            $hint = Get-PreferenceAwareInstallHint -ToolName $missingSystem[0] -ToolType 'generic' -DefaultInstallCommand $bulkInstall
            if ($hint -match '^Install with:\s*(.+)$') {
                $Matches[1]
            }
            else {
                $bulkInstall
            }
        }
        catch {
            $bulkInstall
        }
    }
    else {
        $bulkInstall
    }

    Write-ScriptMessage -Message "Install with: $installHint" -LogLevel Info
    if ($systemPackageManager -ne 'scoop') {
        Write-ScriptMessage -Message "See requirements/linux.txt ($systemPackageManager section) for the full package list" -LogLevel Info
    }
    else {
        Write-ScriptMessage -Message "See requirements/scoop.txt for the full package list" -LogLevel Info
    }
}

Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Some packages are missing"
