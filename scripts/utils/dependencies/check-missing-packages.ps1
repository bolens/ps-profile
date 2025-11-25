<#
scripts/utils/dependencies/check-missing-packages.ps1

.SYNOPSIS
    Checks for missing npm and Python packages required for data format conversions.

.DESCRIPTION
    Scans the codebase to identify all required npm (via pnpm) and Python (via uv) packages
    needed for data format conversions, then checks if they are installed. Reports missing
    packages with installation instructions.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-missing-packages.ps1

    Checks all required packages and reports which are missing.

.NOTES
    This script checks for:
    - npm packages: bson, @msgpack/msgpack, cbor, protobufjs, avsc, flatbuffers, thrift,
      superjson, json5, parquetjs, apache-arrow, base32-encode, base32-decode, qrcode,
      uuid, jsonwebtoken
    - Python packages: h5py, netCDF4, numpy

    Exit Codes:
    - 0 (EXIT_SUCCESS): All packages are installed
    - 1 (EXIT_VALIDATION_FAILURE): Some packages are missing
#>

# Import ModuleImport first (bootstrap)
# Script is in scripts/utils/dependencies/, so go up 3 levels to get to repo root, then join with scripts/lib
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    if (-not $repoRoot) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to determine repository root from script path: $PSScriptRoot"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Source TestSupport to get Test-NpmPackageAvailable
$testSupportPath = Join-Path $repoRoot 'tests' 'TestSupport.ps1'
if (Test-Path $testSupportPath) {
    $env:TERM = 'xterm-256color'
    $env:PS_PROFILE_TEST_MODE = '1'
    . $testSupportPath
}
else {
    Write-ScriptMessage -Message "Warning: TestSupport.ps1 not found, npm package checking may not work" -Level Warning
}

# Collect all required packages from the codebase
$npmPackages = @(
    # Data format conversion packages
    'bson',
    '@msgpack/msgpack',
    'cbor',
    'protobufjs',
    'avsc',
    'flatbuffers',
    'thrift',
    'superjson',
    'json5',
    'parquetjs',
    'apache-arrow',
    # Dev tools packages
    'base32-encode',
    'base32-decode',
    'qrcode',
    'uuid',
    'jsonwebtoken'
)

$pythonPackages = @(
    'h5py',
    'netCDF4',
    'numpy'  # Usually a dependency but let's check
)

$missingNpm = @()
$missingPython = @()

Write-ScriptMessage -Message "Checking npm/pnpm packages..." -LogLevel Info
foreach ($pkg in $npmPackages) {
    if (Get-Command Test-NpmPackageAvailable -ErrorAction SilentlyContinue) {
        if (Test-NpmPackageAvailable -PackageName $pkg) {
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

Write-ScriptMessage -Message "Checking Python/uv packages..." -LogLevel Info

# Check for virtual environment in project root
$venvPython = $null
$venvPath = Join-Path $repoRoot '.venv'
if (Test-Path $venvPath) {
    # Try Windows path first
    $venvPythonPath = Join-Path $venvPath 'Scripts' 'python.exe'
    if (Test-Path $venvPythonPath) {
        $venvPython = $venvPythonPath
        Write-ScriptMessage -Message "  Using virtual environment: $venvPath" -LogLevel Debug
    }
    else {
        # Try Unix-style path
        $venvPythonPath = Join-Path $venvPath 'bin' 'python'
        if (Test-Path $venvPythonPath) {
            $venvPython = $venvPythonPath
            Write-ScriptMessage -Message "  Using virtual environment: $venvPath" -LogLevel Debug
        }
    }
}

foreach ($pkg in $pythonPackages) {
    # Check if Python is available
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
    
    # Check if package is available
    $checkScript = "import sys; import importlib.util; spec = importlib.util.find_spec('$pkg'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-$(Get-Random).py"
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
        Write-ScriptMessage -Message "  ✗ $pkg (error checking)" -IsError
        $missingPython += $pkg
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
}

Write-ScriptMessage -Message ("=" * 60) -LogLevel Info
if ($missingNpm.Count -eq 0 -and $missingPython.Count -eq 0) {
    Write-ScriptMessage -Message "All packages are installed!" -ForegroundColor Green
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
else {
    if ($missingNpm.Count -gt 0) {
        Write-ScriptMessage -Message "Missing npm/pnpm packages:" -IsWarning
        $missingNpm | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }
        $packageJsonFile = Join-Path $repoRoot 'package.json'
        if (Test-Path $packageJsonFile) {
            Write-ScriptMessage -Message "Install with: pnpm add -g $($missingNpm -join ' ')" -LogLevel Info
            Write-ScriptMessage -Message "Or use: pnpm run install-global (from project root with package.json)" -LogLevel Info
        }
        else {
            Write-ScriptMessage -Message "Install with: pnpm add -g $($missingNpm -join ' ')" -LogLevel Info
        }
    }
    
    if ($missingPython.Count -gt 0) {
        Write-ScriptMessage -Message "Missing Python/uv packages:" -IsWarning
        $missingPython | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }
        $requirementsFile = Join-Path $repoRoot 'requirements.txt'
        if (Test-Path $requirementsFile) {
            Write-ScriptMessage -Message "Install with: uv pip install -r requirements.txt" -LogLevel Info
            Write-ScriptMessage -Message "Or install individually: uv pip install $($missingPython -join ' ')" -LogLevel Info
        }
        else {
            Write-ScriptMessage -Message "Install with: uv pip install $($missingPython -join ' ')" -LogLevel Info
        }
    }
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Some packages are missing"
}

