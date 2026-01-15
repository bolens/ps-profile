<#
scripts/utils/dependencies/check-missing-packages.ps1

.SYNOPSIS
    Checks for missing npm, Python, and Scoop packages required for data format conversions and tools.

.DESCRIPTION
    Scans the codebase to identify all required npm (via pnpm), Python (via uv), and Scoop packages
    needed for data format conversions and various tools, then checks if they are installed. 
    Reports missing packages with installation instructions.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-missing-packages.ps1

    Checks all required packages and reports which are missing.

.NOTES
    This script checks for:
    - npm packages: bson, @msgpack/msgpack, cbor, protobufjs, avsc, flatbuffers, thrift,
      superjson, json5, parquetjs, apache-arrow, base32-encode, base32-decode, qrcode,
      uuid, jsonwebtoken, ubjson
    - Python packages: h5py, netCDF4, numpy, astropy, scipy, pandas, polars, pyreadstat,
      ion-python, pyodbc, dbfread, dbf, pyarrow, delta-spark, deltalake, pyiceberg, python-snappy
    - Scoop packages: bat, fd, httpie, zoxide, git-delta, tldr, fzf, ripgrep, eza, procs, dust,
      bottom, navi, gum, docker, podman, docker-compose, lazydocker, pandoc, calibre, djvulibre,
      imagemagick, jq, yq, rclone, minio-client, zstd, gh, kubectl, helm, terraform, aws,
      azure-cli, azure-developer-cli, bun, deno, go, rustup, uv, pixi, pnpm, ngrok, tailscale,
      starship, oh-my-posh, xz, snappy, lz4, ffmpeg, graphicsmagick, miktex

    Exit Codes:
    - 0 (EXIT_SUCCESS): All packages are installed
    - 1 (EXIT_VALIDATION_FAILURE): Some packages are missing
#>

# Import ModuleImport first (bootstrap)
# Script is in scripts/utils/dependencies/, so go up 3 levels to get to repo root, then join with scripts/lib
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    if (-not $repoRoot) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to determine repository root from script path: $PSScriptRoot"
    }
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Source TestSupport to get Test-NpmPackageAvailable
$testSupportPath = Join-Path $repoRoot 'tests' 'TestSupport.ps1'
if ($testSupportPath -and -not [string]::IsNullOrWhiteSpace($testSupportPath) -and (Test-Path -LiteralPath $testSupportPath)) {
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
    'jsonc',
    'parquetjs',
    'apache-arrow',
    'ubjson',
    # Dev tools packages
    'base32-encode',
    'base32-decode',
    'qrcode',
    'uuid',
    'jsonwebtoken'
)

$pythonPackages = @(
    # Scientific data formats
    'h5py',
    'netCDF4',
    'xarray',
    'numpy',
    'astropy',
    'scipy',
    'pandas',
    'polars',
    'pyreadstat',
    # Structured data formats
    'ion-python',
    # Database formats
    'pyodbc',
    'dbfread',
    'dbf',
    # Columnar/binary formats
    'pyarrow',
    'fastparquet',
    'delta-spark',
    'deltalake',
    'pyiceberg',
    # Compression
    'python-snappy'
)

$scoopPackages = @(
    # CLI Tools
    'bat',
    'fd',
    'httpie',
    'zoxide',
    'git-delta',
    'tldr',
    'fzf',
    'ripgrep',
    'eza',
    'procs',
    'dust',
    'bottom',
    'navi',
    'gum',
    # Containers
    'docker',
    'podman',
    'docker-compose',
    'lazydocker',
    # Document Formats
    'pandoc',
    'calibre',
    'djvulibre',
    'imagemagick',
    # File & Data Tools
    'jq',
    'yq',
    'rclone',
    'minio-client',
    'zstd',
    # Git Tools
    'gh',
    # Kubernetes & Cloud
    'kubectl',
    'helm',
    'terraform',
    'aws',
    'azure-cli',
    'azure-developer-cli',
    # Language Runtimes
    'bun',
    'deno',
    'go',
    'rustup',
    'uv',
    'pixi',
    'pnpm',
    # Other Tools
    'ngrok',
    'tailscale',
    'starship',
    'oh-my-posh',
    # Compression Tools (for conversion modules)
    'xz',
    'snappy',
    'lz4',
    # Media Tools
    'ffmpeg',
    'graphicsmagick',
    'imagemagick',
    # LaTeX
    'miktex'
)

$missingNpm = @()
$missingPython = @()
$missingScoop = @()

Write-ScriptMessage -Message "Checking npm/pnpm packages..." -LogLevel Info
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

# Level 2: npm check timing
if ($debugLevel -ge 2) {
    Write-Verbose "[dependencies.check-packages] npm check completed in ${npmCheckDuration}ms"
    Write-Verbose "[dependencies.check-packages] npm missing: $($missingNpm.Count), Errors: $($npmCheckErrors.Count)"
}

if ($npmCheckErrors.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some npm package checks failed" -OperationName 'dependencies.check-npm' -Context @{
            failed_packages = $npmCheckErrors -join ','
            failed_count = $npmCheckErrors.Count
        } -Code 'NpmPackageCheckPartialFailure'
    }
}

Write-ScriptMessage -Message "Checking Python/uv packages..." -LogLevel Info

# Level 1: Python check start
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-packages] Starting Python package check"
}

# Check for virtual environment in project root
$venvPython = $null
$venvPath = Join-Path $repoRoot '.venv'
if ($venvPath -and -not [string]::IsNullOrWhiteSpace($venvPath) -and (Test-Path -LiteralPath $venvPath)) {
    # Try Windows path first
    $venvPythonPath = Join-Path $venvPath 'Scripts' 'python.exe'
    if ($venvPythonPath -and -not [string]::IsNullOrWhiteSpace($venvPythonPath) -and (Test-Path -LiteralPath $venvPythonPath)) {
        $venvPython = $venvPythonPath
        Write-ScriptMessage -Message "  Using virtual environment: $venvPath" -LogLevel Debug
    }
    else {
        # Try Unix-style path
        $venvPythonPath = Join-Path $venvPath 'bin' 'python'
        if ($venvPythonPath -and -not [string]::IsNullOrWhiteSpace($venvPythonPath) -and (Test-Path -LiteralPath $venvPythonPath)) {
            $venvPython = $venvPythonPath
            Write-ScriptMessage -Message "  Using virtual environment: $venvPath" -LogLevel Debug
        }
    }
}

$pythonCheckStartTime = Get-Date
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

# Level 2: Python check timing
if ($debugLevel -ge 2) {
    Write-Verbose "[dependencies.check-packages] Python check completed in ${pythonCheckDuration}ms"
    Write-Verbose "[dependencies.check-packages] Python missing: $($missingPython.Count)"
}

Write-ScriptMessage -Message "Checking Scoop packages..." -LogLevel Info

# Level 1: Scoop check start
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-packages] Starting Scoop package check"
}

# Check if Scoop is available
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-ScriptMessage -Message "  ✗ Scoop is not installed - cannot check Scoop packages" -IsWarning
    Write-ScriptMessage -Message "  Install Scoop from: https://scoop.sh/" -LogLevel Info
    $missingScoop = $scoopPackages  # Mark all as missing if Scoop isn't available
}
else {
    # Load ScoopDetection module if available
    $scoopDetectionPath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'ScoopDetection.psm1'
    if ($scoopDetectionPath -and -not [string]::IsNullOrWhiteSpace($scoopDetectionPath) -and (Test-Path -LiteralPath $scoopDetectionPath)) {
        Import-Module $scoopDetectionPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Load TestScoopHelpers if available
    $testSupportPath = Join-Path $repoRoot 'tests' 'TestSupport.ps1'
    if ($testSupportPath -and -not [string]::IsNullOrWhiteSpace($testSupportPath) -and (Test-Path -LiteralPath $testSupportPath)) {
        $env:PS_PROFILE_TEST_MODE = '1'
        . $testSupportPath
    }
    
    $scoopCheckErrors = [System.Collections.Generic.List[string]]::new()
    foreach ($pkg in $scoopPackages) {
        try {
            if (Get-Command Test-ScoopPackageAvailable -ErrorAction SilentlyContinue) {
                if (Test-ScoopPackageAvailable -PackageName $pkg -ErrorAction Stop) {
                    Write-ScriptMessage -Message "  ✓ $pkg" -ForegroundColor Green
                }
                else {
                    Write-ScriptMessage -Message "  ✗ $pkg" -ForegroundColor Red
                    $missingScoop += $pkg
                }
            }
            else {
                # Fallback: use scoop list directly
                try {
                    $scoopList = & scoop list $pkg 2>&1 -ErrorAction Stop
                    if ($LASTEXITCODE -eq 0 -and $scoopList -match $pkg) {
                        Write-ScriptMessage -Message "  ✓ $pkg" -ForegroundColor Green
                    }
                    else {
                        Write-ScriptMessage -Message "  ✗ $pkg" -ForegroundColor Red
                        $missingScoop += $pkg
                    }
                }
                catch {
                    $scoopCheckErrors.Add($pkg)
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to check Scoop package" -OperationName 'dependencies.check-scoop' -Context @{
                            package_name = $pkg
                        } -Code 'ScoopPackageCheckFailed'
                    }
                    else {
                        Write-ScriptMessage -Message "  ? $pkg (error checking)" -IsWarning
                    }
                    $missingScoop += $pkg
                }
            }
        }
        catch {
            $scoopCheckErrors.Add($pkg)
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dependencies.check-scoop' -Context @{
                    package_name = $pkg
                }
            }
            else {
                Write-ScriptMessage -Message "  ✗ $pkg (error checking)" -IsWarning
            }
            $missingScoop += $pkg
        }
    }
    if ($scoopCheckErrors.Count -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some Scoop package checks failed" -OperationName 'dependencies.check-scoop' -Context @{
                failed_packages = $scoopCheckErrors -join ','
                failed_count = $scoopCheckErrors.Count
            } -Code 'ScoopPackageCheckPartialFailure'
        }
    }
    $scoopCheckDuration = ((Get-Date) - $scoopCheckStartTime).TotalMilliseconds
    
    # Level 2: Scoop check timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[dependencies.check-packages] Scoop check completed in ${scoopCheckDuration}ms"
        Write-Verbose "[dependencies.check-packages] Scoop missing: $($missingScoop.Count), Errors: $($scoopCheckErrors.Count)"
    }
}

# Level 1: Summary generation
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-packages] Generating package check summary"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalCheckDuration = $npmCheckDuration + $pythonCheckDuration + $scoopCheckDuration
    Write-Host "  [dependencies.check-packages] Performance - npm: ${npmCheckDuration}ms, Python: ${pythonCheckDuration}ms, Scoop: ${scoopCheckDuration}ms, Total: ${totalCheckDuration}ms" -ForegroundColor DarkGray
}

Write-ScriptMessage -Message ("=" * 60) -LogLevel Info
if ($missingNpm.Count -eq 0 -and $missingPython.Count -eq 0 -and $missingScoop.Count -eq 0) {
    Write-ScriptMessage -Message "All packages are installed!" -ForegroundColor Green
    Exit-WithCode -ExitCode [ExitCode]::Success
}
else {
    if ($missingNpm.Count -gt 0) {
        Write-ScriptMessage -Message "Missing npm/pnpm packages:" -IsWarning
        $missingNpm | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }
        $packageJsonFile = Join-Path $repoRoot 'package.json'
        if ($packageJsonFile -and -not [string]::IsNullOrWhiteSpace($packageJsonFile) -and (Test-Path -LiteralPath $packageJsonFile)) {
            Write-ScriptMessage -Message "Install with: pnpm add -g $($missingNpm -join ' ')" -LogLevel Info
            Write-ScriptMessage -Message "Or use: pnpm run install-global (from project root with package.json)" -LogLevel Info
        }
        else {
            Write-ScriptMessage -Message "Install with: pnpm add -g $($missingNpm -join ' ')" -LogLevel Info
        }
    }
    
    if ($missingPython.Count -gt 0) {
        Write-ScriptMessage -Message "Missing Python packages:" -IsWarning
        $missingPython | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }
        
        # Use preference-aware install hint if available
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            try {
                $hint = Get-PreferenceAwareInstallHint -ToolName 'python-package' -ToolType 'python-package' -DefaultInstallCommand "pip install $($missingPython[0])"
                # Extract command from hint
                if ($hint -match '^Install with:\s*(.+)$') {
                    $matches[1] -replace '\{package\}', $missingPython[0]
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
        
        $requirementsFile = Join-Path $repoRoot 'requirements.txt'
        if ($requirementsFile -and -not [string]::IsNullOrWhiteSpace($requirementsFile) -and (Test-Path -LiteralPath $requirementsFile)) {
            # Try to get requirements install command
            $reqInstallHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                try {
                    $hint = Get-PreferenceAwareInstallHint -ToolName 'requirements' -ToolType 'python-package' -DefaultInstallCommand "pip install -r requirements.txt"
                    if ($hint -match '^Install with:\s*(.+)$') {
                        $matches[1] -replace '-r requirements\.txt', '-r requirements.txt'
                    }
                    else {
                        "pip install -r requirements.txt"
                    }
                }
                catch {
                    "pip install -r requirements.txt"
                }
            }
            else {
                "pip install -r requirements.txt"
            }
            Write-ScriptMessage -Message "Install with: $reqInstallHint" -LogLevel Info
            Write-ScriptMessage -Message "Or install individually: $installHint" -LogLevel Info
        }
        else {
            Write-ScriptMessage -Message "Install with: $installHint" -LogLevel Info
        }
    }
    
    if ($missingScoop.Count -gt 0) {
        Write-ScriptMessage -Message "Missing system packages:" -IsWarning
        $missingScoop | ForEach-Object { Write-ScriptMessage -Message "  - $_" -IsWarning }
        
        # Use preference-aware install hint if available
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            try {
                $hint = Get-PreferenceAwareInstallHint -ToolName $missingScoop[0] -ToolType 'generic' -DefaultInstallCommand "scoop install $($missingScoop[0])"
                # Extract command from hint
                if ($hint -match '^Install with:\s*(.+)$') {
                    $baseCmd = $matches[1] -replace $missingScoop[0], '{package}'
                    if ($missingScoop.Count -eq 1) {
                        $baseCmd -replace '\{package\}', $missingScoop[0]
                    }
                    else {
                        $baseCmd -replace '\{package\}', ($missingScoop -join ' ')
                    }
                }
                else {
                    "scoop install $($missingScoop -join ' ')"
                }
            }
            catch {
                "scoop install $($missingScoop -join ' ')"
            }
        }
        else {
            "scoop install $($missingScoop -join ' ')"
        }
        
        Write-ScriptMessage -Message "Install with: $installHint" -LogLevel Info
        Write-ScriptMessage -Message "Or install individually: <package-manager> install <package-name>" -LogLevel Info
    }
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Some packages are missing"
}

