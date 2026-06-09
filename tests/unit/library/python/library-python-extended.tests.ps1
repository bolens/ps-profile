<#
tests/unit/library-python-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Python path detection and install hint helpers.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'runtime' 'Python.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'PythonExtended'
    $script:IsolatedPythonCwd = Join-Path $script:TempDir 'isolated-python-cwd'
    $script:SavedPythonLocation = $null
    New-Item -ItemType Directory -Path $script:IsolatedPythonCwd -Force | Out-Null
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

function script:New-FakePythonExecutable {
    param(
        [hashtable]$PackageExitCodes = @{},
        [int]$VersionExitCode = 0,
        [string]$ScriptOutput = 'ok',
        [int]$ScriptExitCode = 0
    )

    $exePath = Join-Path $script:TempDir ("fake-python-{0}.sh" -f (Get-Random))
    $lines = New-Object System.Collections.Generic.List[string]
    $null = $lines.Add('#!/bin/sh')
    $null = $lines.Add('if [ "$1" = "--version" ]; then')
    $null = $lines.Add('  echo "Python 3.11.0"')
    $null = $lines.Add("  exit $VersionExitCode")
    $null = $lines.Add('fi')
    foreach ($entry in $PackageExitCodes.GetEnumerator()) {
        $pkg = $entry.Key
        $code = [int]$entry.Value
        $null = $lines.Add("grep -q '$pkg' `"`$1`" 2>/dev/null && exit $code")
    }
    $null = $lines.Add('if [ -n "$2" ] && [ -f "$2" ]; then')
    $null = $lines.Add("  echo '$ScriptOutput'")
    $null = $lines.Add("  exit $ScriptExitCode")
    $null = $lines.Add('fi')
    $null = $lines.Add('exit 0')
    Set-Content -LiteralPath $exePath -Value ($lines -join "`n") -Encoding UTF8 -NoNewline
    if ($IsLinux -or $IsMacOS) {
        & chmod +x $exePath
    }

    return $exePath
}

function script:Clear-PythonTestEnvironment {
    foreach ($name in @(
            'PYTHON', 'PYTHON_HOME', 'PYTHON_ROOT', 'VIRTUAL_ENV', 'CONDA_PREFIX',
            'PS_PYTHON_RUNTIME', 'PS_DATA_FRAME_LIB', 'PS_PYTHON_PACKAGE_MANAGER',
            'PS_PARQUET_LIB', 'PS_SCIENTIFIC_LIB', 'PS_PROFILE_DEBUG'
        )) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }

    Mark-TestCommandsUnavailable -CommandNames @('python', 'python3', 'py', 'pip', 'uv', 'conda', 'poetry', 'pipenv')

    if (-not $script:SavedPythonLocation) {
        $script:SavedPythonLocation = Get-Location
    }

    Set-Location -LiteralPath $script:IsolatedPythonCwd
}

function script:Invoke-InPythonModuleWithStub {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Body,

        [hashtable]$Stubs = @{}
    )

    $global:TestRuntimePythonStubs = $Stubs
    $global:TestRuntimePythonBody = $Body

    try {
        InModuleScope -ModuleName Python {
            $stubTable = $global:TestRuntimePythonStubs
            if ($null -ne $stubTable) {
                foreach ($entry in $stubTable.GetEnumerator()) {
                    Set-Item -Path "Function:$($entry.Key)" -Value $entry.Value -Force
                }
            }

            & $global:TestRuntimePythonBody
        }
    }
    finally {
        Remove-Variable -Name TestRuntimePythonStubs, TestRuntimePythonBody -Scope Global -ErrorAction SilentlyContinue
    }
}

function script:Restore-PythonTestEnvironment {
    if ($script:SavedPythonLocation) {
        Set-Location -Path $script:SavedPythonLocation
        $script:SavedPythonLocation = $null
    }
}

AfterAll {
    Restore-PythonTestEnvironment
    Remove-Module Python -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Python extended scenarios' {
    Context 'Get-PythonPath environment hooks' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Uses PYTHON env var when it points to an existing executable' {
            $fakePython = New-FakePythonExecutable
            $original = $env:PYTHON
            try {
                $env:PYTHON = $fakePython
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                }
                else {
                    $env:PYTHON = $original
                }
            }
        }

        It 'Uses CONDA_PREFIX when bin/python exists beneath it' {
            $condaRoot = Join-Path $script:TempDir 'conda-env'
            $condaBin = Join-Path $condaRoot 'bin'
            New-Item -ItemType Directory -Path $condaBin -Force | Out-Null
            $fakePython = Join-Path $condaBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            $original = $env:CONDA_PREFIX
            try {
                $env:CONDA_PREFIX = $condaRoot
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:CONDA_PREFIX -ErrorAction SilentlyContinue
                }
                else {
                    $env:CONDA_PREFIX = $original
                }
            }
        }

        It 'Uses PYTHON_ROOT when bin/python exists beneath it' {
            $pythonRoot = Join-Path $script:TempDir 'python-root'
            $pythonBin = Join-Path $pythonRoot 'bin'
            New-Item -ItemType Directory -Path $pythonBin -Force | Out-Null
            $fakePython = Join-Path $pythonBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            $original = $env:PYTHON_ROOT
            try {
                $env:PYTHON_ROOT = $pythonRoot
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PYTHON_ROOT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PYTHON_ROOT = $original
                }
            }
        }

        It 'Honors PS_PYTHON_RUNTIME when set to python3' {
            Mark-TestCommandsUnavailable -CommandNames @('python', 'py')
            Set-TestCommandAvailabilityState -CommandName 'python3' -Available $true
            Setup-CapturingCommandMock -CommandName 'python3' -Output 'Python 3.11.0' -MarkAvailable $true

            $original = $env:PS_PYTHON_RUNTIME
            try {
                $env:PS_PYTHON_RUNTIME = 'python3'
                Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'empty-runtime-root') | Should -Be 'python3'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PYTHON_RUNTIME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PYTHON_RUNTIME = $original
                }
            }
        }

        It 'Returns null and emits warnings when no Python can be detected' {
            Clear-PythonTestEnvironment
            Enable-TestStructuredLogging
            Mock Get-Command {
                param($Name)
                if ($Name -in @('python', 'python3', 'py')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'empty-no-python-root') |
                    Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Detects repository root from a .git directory when RepoRoot is omitted' {
            $repoRoot = Join-Path $script:TempDir 'git-repo'
            $venvBin = Join-Path $repoRoot '.venv' 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $repoRoot '.git') -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            Push-Location $repoRoot
            try {
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Get-PythonPath without Validation helpers' {
        BeforeEach {
            Clear-PythonTestEnvironment
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
        }

        It 'Resolves PYTHON via manual path checks when validation helpers are unavailable' {
            $fakePython = New-FakePythonExecutable
            $original = $env:PYTHON
            try {
                $env:PYTHON = $fakePython
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                }
                else {
                    $env:PYTHON = $original
                }
            }
        }
    }

    Context 'Invoke-PythonScript' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Throws when the script path does not exist' {
            $missingScript = Join-Path $script:TempDir 'missing-script.py'
            { Invoke-PythonScript -ScriptPath $missingScript } | Should -Throw '*not found*'
        }

        It 'Throws when Python is not available' {
            $testScript = Join-Path $script:TempDir 'probe.py'
            Set-Content -LiteralPath $testScript -Value 'print("probe")' -Encoding UTF8
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { $null }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } | Should -Throw '*not available*'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Executes a script and returns output when Python is available' {
            $testScript = Join-Path $script:TempDir 'hello.py'
            Set-Content -LiteralPath $testScript -Value 'print("ignored")' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output 'hello-from-fake-python'
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath | Should -Be 'hello-from-fake-python'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Throws when the Python executable fails the version check' {
            $testScript = Join-Path $script:TempDir 'version-fail.py'
            Set-Content -LiteralPath $testScript -Value 'print("x")' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output 'broken' -ExitCode 1
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } | Should -Throw '*failed to execute*'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Throws with script output when execution exits non-zero' {
            $testScript = Join-Path $script:TempDir 'fail.py'
            Set-Content -LiteralPath $testScript -Value 'raise SystemExit(2)' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output 'ERROR: boom' -ExitCode 0 -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'Python 3.11.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 2
                return 'ERROR: boom'
            }
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } | Should -Throw '*exit code 2*'
                }
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-PythonPackageManagerPreference' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns a hashtable with manager metadata keys' {
            $result = Get-PythonPackageManagerPreference

            $result | Should -Not -BeNullOrEmpty
            $result.Keys | Should -Contain 'Manager'
            $result.Keys | Should -Contain 'Available'
            $result.Keys | Should -Contain 'InstallCommand'
        }

        It 'Prefers uv when PS_PYTHON_PACKAGE_MANAGER is auto and uv is available' {
            Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
            Setup-CapturingCommandMock -CommandName 'uv' -Output '' -MarkAvailable $true

            $result = Get-PythonPackageManagerPreference
            $result.Manager | Should -Be 'uv'
            $result.Available | Should -Be $true
        }

        It 'Falls back to pip install command when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('uv', 'pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $result = Get-PythonPackageManagerPreference
            $result.Available | Should -Be $false
            $result.InstallCommand | Should -Be 'pip install {package}'
        }

        It 'Honors explicit pip preference with uv fallback' {
            Set-TestCommandAvailabilityState -CommandName 'pip' -Available $true
            Setup-CapturingCommandMock -CommandName 'pip' -Output '' -MarkAvailable $true

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'pip'
                $result = Get-PythonPackageManagerPreference
                $result.Manager | Should -Be 'pip'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PYTHON_PACKAGE_MANAGER = $original
                }
            }
        }
    }

    Context 'Get-PythonPackageInstallCommand' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Falls back to pip install when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('uv', 'pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            Get-PythonPackageInstallCommand -PackageName 'requests' |
                Should -Be 'pip install --user requests'
        }
    }

    Context 'Get-DataFrameLibraryPreference' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns unavailable defaults when PythonCmd is missing' {
            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-PythonPath' = { $null }
            } -Body {
                $result = Get-DataFrameLibraryPreference
                $result.Available | Should -Be $false
                $result.Library | Should -Be 'pandas'
            }
        }

        It 'Detects pandas availability through the Python probe script' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pandas = 0; polars = 1 }
            $result = Get-DataFrameLibraryPreference -PythonCmd $fakePython
            $result.PandasAvailable | Should -Be $true
            $result.Library | Should -Be 'pandas'
        }

        It 'Selects polars when pandas is unavailable and polars is installed' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pandas = 1; polars = 0 }
            $result = Get-DataFrameLibraryPreference -PythonCmd $fakePython
            $result.PolarsAvailable | Should -Be $true
            $result.Library | Should -Be 'polars'
        }
    }

    Context 'Get-ParquetLibraryPreference' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns unavailable defaults when PythonCmd is missing' {
            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-PythonPath' = { $null }
            } -Body {
                $result = Get-ParquetLibraryPreference
                $result.Available | Should -Be $false
                $result.Library | Should -Be 'pyarrow'
            }
        }

        It 'Prefers pyarrow when both parquet libraries are available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pyarrow = 0; fastparquet = 0 }
            $result = Get-ParquetLibraryPreference -PythonCmd $fakePython
            $result.BothAvailable | Should -Be $true
            $result.Library | Should -Be 'pyarrow'
        }
    }

    Context 'Get-ScientificLibraryPreference' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns unavailable defaults when PythonCmd is missing' {
            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-PythonPath' = { $null }
            } -Body {
                $result = Get-ScientificLibraryPreference
                $result.Available | Should -Be $false
                $result.Library | Should -Be 'netcdf4'
            }
        }

        It 'Prefers xarray in auto mode when xarray is available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{
                xarray  = 0
                netCDF4 = 1
                h5py    = 1
            }
            $result = Get-ScientificLibraryPreference -PythonCmd $fakePython
            $result.XarrayAvailable | Should -Be $true
            $result.Library | Should -Be 'xarray'
        }
    }

    Context 'Expand-EmbeddedPythonInstallHints' {
        It 'Replaces install placeholders with a recommendation command' {
            $scriptText = 'Run __PYTHON_INSTALL_CMD__ to continue'

            $expanded = Expand-EmbeddedPythonInstallHints -Script $scriptText -PackageNames @('requests')

            $expanded | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $expanded | Should -Match 'requests'
        }

        It 'Replaces placeholders via Resolve-PythonInstallHintMessage' {
            $message = 'Install packages: __PYTHON_INSTALL_CMD__'

            $resolved = Resolve-PythonInstallHintMessage -Message $message -PackageNames @('numpy')

            $resolved | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $resolved | Should -Match 'numpy'
        }

        It 'Returns the original script when no placeholder is present' {
            $scriptText = 'No install hint here'
            Expand-EmbeddedPythonInstallHints -Script $scriptText -PackageNames 'pandas' |
                Should -Be $scriptText
        }

        It 'Returns the original message when Resolve-PythonInstallHintMessage has no placeholder' {
            $message = 'No install hint here'
            Resolve-PythonInstallHintMessage -Message $message -PackageNames @('numpy') |
                Should -Be $message
        }
    }

    Context 'Get-PythonPackageInstallRecommendation' {
        It 'Joins multiple package names into one install command' {
            InModuleScope -ModuleName Python {
                $result = Get-PythonPackageInstallRecommendation -PackageNames @('pandas', 'polars')
                $result | Should -Match 'pandas'
                $result | Should -Match 'polars'
            }
        }

        It 'Falls back to pip install when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('uv', 'pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            InModuleScope -ModuleName Python {
                Get-PythonPackageInstallRecommendation -PackageNames @('requests') |
                    Should -Match 'pip install\s+requests'
            }
        }
    }

    Context 'Get-PythonPath additional environment hooks' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Uses PYTHON_HOME when python exists directly beneath it' {
            $pythonHome = Join-Path $script:TempDir 'python-home-direct'
            New-Item -ItemType Directory -Path $pythonHome -Force | Out-Null
            $fakePython = Join-Path $pythonHome 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            $original = $env:PYTHON_HOME
            try {
                $env:PYTHON_HOME = $pythonHome
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PYTHON_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PYTHON_HOME = $original
                }
            }
        }

        It 'Uses VIRTUAL_ENV when bin/python exists beneath it' {
            $venvRoot = Join-Path $script:TempDir 'virtual-env'
            $venvBin = Join-Path $venvRoot 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            $original = $env:VIRTUAL_ENV
            try {
                $env:VIRTUAL_ENV = $venvRoot
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                }
                else {
                    $env:VIRTUAL_ENV = $original
                }
            }
        }

        It 'Emits level 3 debug output when Python is resolved via PYTHON env var' {
            $fakePython = New-FakePythonExecutable
            $originalDebug = $env:PS_PROFILE_DEBUG
            $original = $env:PYTHON
            $env:PS_PROFILE_DEBUG = '3'
            try {
                $env:PYTHON = $fakePython
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                }
                else {
                    $env:PYTHON = $original
                }
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Invoke-PythonScript extended execution paths' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns output on successful execution with debug level 2 enabled' {
            $testScript = Join-Path $script:TempDir 'success-debug.py'
            Set-Content -LiteralPath $testScript -Value 'print("ok")' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output 'success-output' -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'Python 3.11.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 0
                return 'success-output'
            }
            $global:TestPythonScriptPath = $testScript
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath -Arguments 'arg1' |
                        Should -Be 'success-output'
                }
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Throws when script exits non-zero with no output' {
            $testScript = Join-Path $script:TempDir 'silent-fail.py'
            Set-Content -LiteralPath $testScript -Value 'pass' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output '' -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'Python 3.11.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 1
                return ''
            }
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } |
                        Should -Throw '*no output*'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Filters WARNING lines from failure output before throwing' {
            $testScript = Join-Path $script:TempDir 'warning-fail.py'
            Set-Content -LiteralPath $testScript -Value 'pass' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output @('WARNING: noise', 'real error') -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'Python 3.11.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 1
                return @('WARNING: noise', 'real error')
            }
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } |
                        Should -Throw '*real error*'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-PythonPackageManagerPreference extended' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Prefers conda when PS_PYTHON_PACKAGE_MANAGER is conda and conda is available' {
            Set-TestCommandAvailabilityState -CommandName 'conda' -Available $true
            Setup-CapturingCommandMock -CommandName 'conda' -Output '' -MarkAvailable $true

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'conda'
                $result = Get-PythonPackageManagerPreference
                $result.Manager | Should -Be 'conda'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PYTHON_PACKAGE_MANAGER = $original
                }
            }
        }

        It 'Prefers poetry when PS_PYTHON_PACKAGE_MANAGER is poetry and poetry is available' {
            Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $true
            Setup-CapturingCommandMock -CommandName 'poetry' -Output '' -MarkAvailable $true

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'poetry'
                $result = Get-PythonPackageManagerPreference
                $result.Manager | Should -Be 'poetry'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PYTHON_PACKAGE_MANAGER = $original
                }
            }
        }
    }

    Context 'Library preference environment hooks' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Honors PS_DATA_FRAME_LIB polars preference when polars is available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pandas = 1; polars = 0 }
            $original = $env:PS_DATA_FRAME_LIB
            try {
                $env:PS_DATA_FRAME_LIB = 'polars'
                $result = Get-DataFrameLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'polars'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_DATA_FRAME_LIB -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_DATA_FRAME_LIB = $original
                }
            }
        }

        It 'Honors PS_PARQUET_LIB fastparquet preference when fastparquet is available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pyarrow = 1; fastparquet = 0 }
            $original = $env:PS_PARQUET_LIB
            try {
                $env:PS_PARQUET_LIB = 'fastparquet'
                $result = Get-ParquetLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'fastparquet'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PARQUET_LIB -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PARQUET_LIB = $original
                }
            }
        }

        It 'Honors PS_SCIENTIFIC_LIB netcdf4 preference when netCDF4 is available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{
                xarray  = 1
                netCDF4 = 0
                h5py    = 1
            }
            $original = $env:PS_SCIENTIFIC_LIB
            try {
                $env:PS_SCIENTIFIC_LIB = 'netcdf4'
                $result = Get-ScientificLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'netcdf4'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_SCIENTIFIC_LIB -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_SCIENTIFIC_LIB = $original
                }
            }
        }

        It 'Falls back to alternate library when preferred dataframe library is unavailable' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pandas = 1; polars = 0 }
            $original = $env:PS_DATA_FRAME_LIB
            try {
                $env:PS_DATA_FRAME_LIB = 'pandas'
                $result = Get-DataFrameLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'polars'
                $result.Available | Should -Be $true
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_DATA_FRAME_LIB -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_DATA_FRAME_LIB = $original
                }
            }
        }
    }

    Context 'Get-PythonPackageInstallCommand extended' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns global pip install fallback when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('uv', 'pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            Get-PythonPackageInstallCommand -PackageName 'numpy' -Global |
                Should -Match 'pip install\s+numpy'
        }
    }

    Context 'Get-PythonPath runtime preference extended' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Honors PS_PYTHON_RUNTIME when set to python' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'python') {
                    return [PSCustomObject]@{ Name = 'python' }
                }
                if ($Name -in @('python3', 'py')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_RUNTIME
            try {
                $env:PS_PYTHON_RUNTIME = 'python'
                Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'runtime-python') | Should -Be 'python'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PYTHON_RUNTIME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PYTHON_RUNTIME = $original
                }
            }
        }

        It 'Emits level 2 debug output when resolving system python3' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'python3') {
                    return [PSCustomObject]@{ Name = 'python3' }
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'
            try {
                Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'debug-python3') | Should -Be 'python3'
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Invoke-PythonScript version and access errors' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Throws when Python version check throws an exception' {
            $testScript = Join-Path $script:TempDir 'version-throw.py'
            Set-Content -LiteralPath $testScript -Value 'print("x")' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-runner' -Output '' -OnInvoke {
                if ($args -contains '--version') {
                    throw 'version probe failure'
                }

                return 'ok'
            }
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-runner' }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } |
                        Should -Throw '*not executable*'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Scientific and parquet preference extended' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Prefers h5py when PS_SCIENTIFIC_LIB is h5py and h5py is available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{
                xarray  = 1
                netCDF4 = 1
                h5py    = 0
            }
            $original = $env:PS_SCIENTIFIC_LIB
            try {
                $env:PS_SCIENTIFIC_LIB = 'h5py'
                $result = Get-ScientificLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'h5py'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_SCIENTIFIC_LIB -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_SCIENTIFIC_LIB = $original
                }
            }
        }

        It 'Returns unavailable parquet defaults when neither library is installed' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pyarrow = 1; fastparquet = 1 }
            $result = Get-ParquetLibraryPreference -PythonCmd $fakePython
            $result.Available | Should -Be $false
        }

        It 'Prefers pipenv when PS_PYTHON_PACKAGE_MANAGER is pipenv and pipenv is available' {
            Set-TestCommandAvailabilityState -CommandName 'pipenv' -Available $true
            Setup-CapturingCommandMock -CommandName 'pipenv' -Output '' -MarkAvailable $true

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'pipenv'
                $result = Get-PythonPackageManagerPreference
                $result.Manager | Should -Be 'pipenv'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PYTHON_PACKAGE_MANAGER = $original
                }
            }
        }
    }

    Context 'Expand-EmbeddedPythonInstallHints global installs' {
        It 'Replaces placeholders with a global install recommendation' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('uv', 'pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $scriptText = 'Run __PYTHON_INSTALL_CMD__ globally'
            $expanded = Expand-EmbeddedPythonInstallHints -Script $scriptText -PackageNames @('requests') -Global
            $expanded | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $expanded | Should -Match 'requests'
        }
    }
}
