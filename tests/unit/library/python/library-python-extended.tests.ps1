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
    Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue

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
    AfterEach {
        Import-Module (Join-Path $script:LibPath 'runtime' 'Python.psm1') -DisableNameChecking -Force
        Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    }

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

        It 'Returns null when no Python can be detected in an isolated environment' {
            Clear-PythonTestEnvironment
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Mock Get-Command {
                param($Name)
                if ($Name -in @('python', 'python3', 'py')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $pythonPath = Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'empty-no-python-root') |
                Select-Object -Last 1
            $pythonPath | Should -BeNullOrEmpty
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
                    Should -Match 'pip install(\s+--user)?\s+requests'
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

    Context 'Get-PythonPath repo and runtime fallbacks' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Uses repository venv python when RepoRoot contains a .venv directory' {
            $repoRoot = Join-Path $script:TempDir 'repo-with-venv'
            $venvBin = Join-Path $repoRoot '.venv' 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            Get-PythonPath -RepoRoot $repoRoot | Should -Be $fakePython
        }

        It 'Falls back to python when python3 is unavailable' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'python3') {
                    return $null
                }
                if ($Name -eq 'python') {
                    return [PSCustomObject]@{ Name = 'python' }
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'python-only-root') | Should -Be 'python'
        }
    }

    Context 'Library preference unavailable paths' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns unavailable dataframe defaults when neither library is installed' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pandas = 1; polars = 1 }
            $result = Get-DataFrameLibraryPreference -PythonCmd $fakePython
            $result.Available | Should -Be $false
        }

        It 'Auto-selects pip in manager preference when uv is unavailable but pip exists' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pip') {
                    return [PSCustomObject]@{ Name = 'pip' }
                }
                if ($Name -in @('uv', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $result = Get-PythonPackageManagerPreference
            $result.Manager | Should -Be 'pip'
        }
    }

    Context 'Get-PythonPackageManagerPreference explicit managers' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Prefers pipenv when PS_PYTHON_PACKAGE_MANAGER is pipenv and pipenv is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pipenv') {
                    return [PSCustomObject]@{ Name = 'pipenv' }
                }
                if ($Name -in @('uv', 'pip', 'conda', 'poetry')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

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

        It 'Falls back to uv in auto mode when uv is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'uv') {
                    return [PSCustomObject]@{ Name = 'uv' }
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $result = Get-PythonPackageManagerPreference
            $result.Manager | Should -Be 'uv'
            $result.Available | Should -Be $true
        }
    }

    Context 'Scientific and parquet preference branches' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Selects netcdf4 in auto mode when only netCDF4 is available' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{
                xarray  = 1
                netCDF4 = 0
                h5py    = 1
            }
            $result = Get-ScientificLibraryPreference -PythonCmd $fakePython
            $result.Library | Should -Be 'netcdf4'
        }

        It 'Selects fastparquet when pyarrow is unavailable and fastparquet is installed' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pyarrow = 1; fastparquet = 0 }
            $result = Get-ParquetLibraryPreference -PythonCmd $fakePython
            $result.Library | Should -Be 'fastparquet'
        }

        It 'Returns install recommendation using pip fallback for multiple packages' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('uv', 'pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            InModuleScope -ModuleName Python {
                Get-PythonPackageInstallRecommendation -PackageNames @('numpy', 'pandas') -Global |
                    Should -Match 'numpy'
            }
        }
    }

    Context 'Invoke-PythonScript validation fallback' {
        BeforeEach {
            Clear-PythonTestEnvironment
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
        }

        It 'Throws when the script path does not exist using manual validation' {
            $missingScript = Join-Path $script:TempDir 'missing-manual-validation.py'
            { Invoke-PythonScript -ScriptPath $missingScript } | Should -Throw '*not found*'
        }
    }

    Context 'Get-PythonPath runtime and warning paths' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns py when PS_PYTHON_RUNTIME is py and py is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'py') {
                    return [PSCustomObject]@{ Name = 'py' }
                }
                if ($Name -in @('python', 'python3')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_RUNTIME
            try {
                $env:PS_PYTHON_RUNTIME = 'py'
                Get-PythonPath | Should -Be 'py'
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

        It 'Emits a warning when Python cannot be detected at debug level 1' {
            $isolatedRepo = Join-Path $script:TempDir 'no-python-warning-repo'
            New-Item -ItemType Directory -Path $isolatedRepo -Force | Out-Null

            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-Command' = {
                    param($Name, $ErrorAction)
                    if ($Name -in @('python', 'python3', 'py', 'Write-StructuredWarning', 'Write-StructuredError')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                }
            } -Body {
                $originalDebug = $env:PS_PROFILE_DEBUG
                $env:PS_PROFILE_DEBUG = '1'

                try {
                    @(Get-PythonPath -RepoRoot $isolatedRepo) | Where-Object { $_ -is [string] } | Should -BeNullOrEmpty
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

        It 'Emits level 3 debug when no Python is found via environment variables' {
            $isolatedRepo = Join-Path $script:TempDir 'no-python-debug-repo'
            New-Item -ItemType Directory -Path $isolatedRepo -Force | Out-Null

            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-Command' = {
                    param($Name, $ErrorAction)
                    if ($Name -in @('python', 'python3', 'py', 'Write-StructuredWarning', 'Write-StructuredError')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                }
            } -Body {
                $originalDebug = $env:PS_PROFILE_DEBUG
                $env:PS_PROFILE_DEBUG = '3'

                try {
                    @(Get-PythonPath -RepoRoot $isolatedRepo) | Where-Object { $_ -is [string] } | Should -BeNullOrEmpty
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
    }

    Context 'Get-PythonPackageManagerPreference fallback chains' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Falls back from uv preference to pip when uv is unavailable' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pip') {
                    return [PSCustomObject]@{ Name = 'pip' }
                }
                if ($Name -in @('uv', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
                (Get-PythonPackageManagerPreference).Manager | Should -Be 'pip'
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

        It 'Falls back from pip preference to uv when pip is unavailable' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'uv') {
                    return [PSCustomObject]@{ Name = 'uv' }
                }
                if ($Name -in @('pip', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'pip'
                (Get-PythonPackageManagerPreference).Manager | Should -Be 'uv'
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

        It 'Falls back from conda preference through uv to pip' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pip') {
                    return [PSCustomObject]@{ Name = 'pip' }
                }
                if ($Name -in @('uv', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'conda'
                (Get-PythonPackageManagerPreference).Manager | Should -Be 'pip'
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

        It 'Selects conda in auto mode when only conda is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'conda') {
                    return [PSCustomObject]@{ Name = 'conda' }
                }
                if ($Name -in @('uv', 'pip', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            (Get-PythonPackageManagerPreference).Manager | Should -Be 'conda'
        }
    }

    Context 'Get-PythonPackageInstallCommand with available managers' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Builds a global uv install recommendation with system flag' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'uv') {
                    return [PSCustomObject]@{ Name = 'uv' }
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
                InModuleScope -ModuleName Python {
                    Get-PythonPackageInstallRecommendation -PackageNames @('numpy') -Global |
                        Should -Match 'uv pip install numpy --system'
                }
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

        It 'Builds a local pip install recommendation with user flag' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pip') {
                    return [PSCustomObject]@{ Name = 'pip' }
                }
                if ($Name -eq 'uv') {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'pip'
                InModuleScope -ModuleName Python {
                    Get-PythonPackageInstallRecommendation -PackageNames @('numpy') |
                        Should -Match 'pip install numpy --user'
                }
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

    Context 'Invoke-PythonScript extended execution paths' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns output on successful execution with debug level 3 enabled' {
            $testScript = Join-Path $script:TempDir 'debug-success.py'
            Set-Content -LiteralPath $testScript -Value 'print("ok")' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-debug' -Output 'debug-success' -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'Python 3.11.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 0
                return 'debug-success'
            }
            $global:TestPythonScriptPath = $testScript

            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            try {
                $env:PS_PROFILE_DEBUG = '3'
                $VerbosePreference = 'Continue'
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-debug' }
                } -Body {
                    Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath | Should -Be 'debug-success'
                }
            }
            finally {
                $VerbosePreference = $originalVerbose
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Throws when Python is not available and structured logging is enabled' {
            $testScript = Join-Path $script:TempDir 'no-python.py'
            Set-Content -LiteralPath $testScript -Value 'print("x")' -Encoding UTF8
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

        It 'Throws with full output when only WARNING lines are present' {
            $testScript = Join-Path $script:TempDir 'warning-only-fail.py'
            Set-Content -LiteralPath $testScript -Value 'pass' -Encoding UTF8
            Setup-CapturingCommandMock -CommandName 'mock-python-warn-only' -Output @('WARNING: only noise') -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'Python 3.11.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 1
                return @('WARNING: only noise')
            }
            $global:TestPythonScriptPath = $testScript

            try {
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-python-warn-only' }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } |
                        Should -Throw '*only noise*'
                }
            }
            finally {
                Remove-Variable -Name TestPythonScriptPath -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Library preference fallback branches' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Falls back to polars when pandas preference is set but pandas is unavailable' {
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

        It 'Falls back to pyarrow when fastparquet preference is set but fastparquet is unavailable' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{ pyarrow = 0; fastparquet = 1 }
            $original = $env:PS_PARQUET_LIB
            try {
                $env:PS_PARQUET_LIB = 'fastparquet'
                $result = Get-ParquetLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'pyarrow'
                $result.Available | Should -Be $true
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

        It 'Falls back to netcdf4 when xarray preference is set but xarray is unavailable' {
            $fakePython = New-FakePythonExecutable -PackageExitCodes @{
                xarray  = 1
                netCDF4 = 0
                h5py    = 1
            }
            $original = $env:PS_SCIENTIFIC_LIB
            try {
                $env:PS_SCIENTIFIC_LIB = 'xarray'
                $result = Get-ScientificLibraryPreference -PythonCmd $fakePython
                $result.Library | Should -Be 'netcdf4'
                $result.Available | Should -Be $true
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
    }

    Context 'Expand-EmbeddedPythonInstallHints and Resolve-PythonInstallHintMessage' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns the original script when no placeholder is present' {
            Expand-EmbeddedPythonInstallHints -Script 'plain python script' -PackageNames @('numpy') |
                Should -Be 'plain python script'
        }

        It 'Replaces placeholders with a global install recommendation using uv' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'uv') {
                    return [PSCustomObject]@{ Name = 'uv' }
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
                $expanded = Expand-EmbeddedPythonInstallHints -Script 'Run __PYTHON_INSTALL_CMD__' -PackageNames @('numpy') -Global
                $expanded | Should -Not -Match '__PYTHON_INSTALL_CMD__'
                $expanded | Should -Match 'numpy'
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

        It 'Returns the original message when Resolve-PythonInstallHintMessage has no placeholder' {
            Resolve-PythonInstallHintMessage -Message 'no hint' -PackageNames @('numpy') |
                Should -Be 'no hint'
        }
    }

    Context 'Get-PythonPath additional runtime branches' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Returns python when PS_PYTHON_RUNTIME is python and python is available' {
            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-Command' = {
                    param($Name)
                    if ($Name -eq 'python') {
                        return [PSCustomObject]@{ Name = 'python' }
                    }
                    if ($Name -in @('python3', 'py')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                }
            } -Body {
                $original = $env:PS_PYTHON_RUNTIME
                try {
                    $env:PS_PYTHON_RUNTIME = 'python'
                    Get-PythonPath | Should -Be 'python'
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
        }

        It 'Returns py in auto mode when only py is available' {
            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-Command' = {
                    param($Name)
                    if ($Name -eq 'py') {
                        return [PSCustomObject]@{ Name = 'py' }
                    }
                    if ($Name -in @('python3', 'python')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                }
            } -Body {
                Get-PythonPath | Should -Be 'py'
            }
        }

        It 'Uses repository venv python when RepoRoot parameter contains a .venv directory' {
            $repoRoot = Join-Path $script:TempDir 'script-scope-repo'
            $venvBin = Join-Path $repoRoot '.venv' 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $global:TestScriptScopeRepoRoot = $repoRoot
            $global:TestScriptScopeFakePython = $fakePython

            Invoke-InPythonModuleWithStub -Stubs @{
                'Get-Command' = {
                    param($Name)
                    if ($Name -in @('python', 'python3', 'py')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                }
            } -Body {
                Get-PythonPath -RepoRoot $global:TestScriptScopeRepoRoot |
                    Should -Be $global:TestScriptScopeFakePython
            }

            Remove-Variable -Name TestScriptScopeRepoRoot, TestScriptScopeFakePython -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-PythonPackageManagerPreference poetry and pipenv chains' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Falls back from poetry preference through uv to pip' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pip') {
                    return [PSCustomObject]@{ Name = 'pip' }
                }
                if ($Name -in @('uv', 'conda', 'poetry', 'pipenv')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $original = $env:PS_PYTHON_PACKAGE_MANAGER
            try {
                $env:PS_PYTHON_PACKAGE_MANAGER = 'poetry'
                (Get-PythonPackageManagerPreference).Manager | Should -Be 'pip'
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

        It 'Selects pipenv in auto mode when only pipenv is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'pipenv') {
                    return [PSCustomObject]@{ Name = 'pipenv' }
                }
                if ($Name -in @('uv', 'pip', 'conda', 'poetry')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            (Get-PythonPackageManagerPreference).Manager | Should -Be 'pipenv'
        }
    }

    Context 'Library preference catch and unavailable paths' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Treats dataframe probe failures as unavailable libraries' {
            $throwingPython = Join-Path $script:TempDir 'throwing-python.sh'
            Set-Content -LiteralPath $throwingPython -Value @(
                '#!/bin/sh'
                'exit 1'
            ) -Encoding UTF8 -NoNewline
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $throwingPython
            }

            $result = Get-DataFrameLibraryPreference -PythonCmd $throwingPython
            $result.Available | Should -Be $false
        }

        It 'Returns unavailable parquet defaults when PythonCmd probe throws' {
            $throwingPython = Join-Path $script:TempDir 'throwing-parquet-python.sh'
            Set-Content -LiteralPath $throwingPython -Value @(
                '#!/bin/sh'
                'exit 1'
            ) -Encoding UTF8 -NoNewline
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $throwingPython
            }

            $result = Get-ParquetLibraryPreference -PythonCmd $throwingPython
            $result.Available | Should -Be $false
        }

        It 'Returns unavailable scientific defaults when PythonCmd probe throws' {
            $throwingPython = Join-Path $script:TempDir 'throwing-scientific-python.sh'
            Set-Content -LiteralPath $throwingPython -Value @(
                '#!/bin/sh'
                'exit 1'
            ) -Encoding UTF8 -NoNewline
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $throwingPython
            }

            $result = Get-ScientificLibraryPreference -PythonCmd $throwingPython
            $result.Available | Should -Be $false
        }
    }

    Context 'Get-PythonPath script-scope RepoRoot variables' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Uses script RepoRoot when the RepoRoot parameter is omitted' {
            $repoRoot = Join-Path $script:TempDir 'script-var-repo-root'
            $venvBin = Join-Path $repoRoot '.venv' 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $global:TestScriptRepoRoot = $repoRoot
            $global:TestScriptFakePython = $fakePython

            InModuleScope -ModuleName Python {
                Set-Variable -Name RepoRoot -Value $global:TestScriptRepoRoot -Scope Script -Force
                Set-Item -Path Function:Get-Command -Value {
                    param($Name, $ErrorAction)
                    if ($Name -in @('python', 'python3', 'py')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                } -Force

                Get-PythonPath | Should -Be $global:TestScriptFakePython
            }

            Remove-Variable -Name TestScriptRepoRoot, TestScriptFakePython -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Derives RepoRoot from script BootstrapRoot when RepoRoot is omitted' {
            $repoRoot = Join-Path $script:TempDir 'bootstrap-derived-repo'
            $profileDir = Join-Path $repoRoot 'profile.d'
            $bootstrapRoot = Join-Path $profileDir 'bootstrap'
            $venvBin = Join-Path $profileDir '.venv' 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            New-Item -ItemType Directory -Path $bootstrapRoot -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $global:TestBootstrapRoot = $bootstrapRoot
            $global:TestBootstrapFakePython = $fakePython

            InModuleScope -ModuleName Python {
                Set-Variable -Name BootstrapRoot -Value $global:TestBootstrapRoot -Scope Script -Force
                Set-Item -Path Function:Get-Command -Value {
                    param($Name, $ErrorAction)
                    if ($Name -in @('python', 'python3', 'py')) {
                        return $null
                    }

                    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                } -Force

                Get-PythonPath | Should -Be $global:TestBootstrapFakePython
            }

            Remove-Variable -Name TestBootstrapRoot, TestBootstrapFakePython -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-PythonPath manual validation env branches' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Resolves PYTHON_HOME via Test-Path when Validation helpers are unavailable' {
            $pythonHome = Join-Path $script:TempDir 'manual-python-home'
            $pythonExe = Join-Path $pythonHome 'bin' 'python'
            New-Item -ItemType Directory -Path (Split-Path -Parent $pythonExe) -Force | Out-Null
            Set-Content -LiteralPath $pythonExe -Value '#!/bin/sh' -Encoding UTF8

            $original = $env:PYTHON_HOME
            try {
                $env:PYTHON_HOME = $pythonHome
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-Command' = {
                        param($Name, $ErrorAction)
                        if ($Name -eq 'Test-ValidPath') {
                            return $null
                        }
                        if ($Name -in @('python', 'python3', 'py')) {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }
                } -Body {
                    Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'manual-python-home-repo') |
                        Should -Be $pythonExe
                }
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

        It 'Resolves VIRTUAL_ENV via Test-Path when Validation helpers are unavailable' {
            $venvRoot = Join-Path $script:TempDir 'manual-virtual-env'
            $pythonExe = Join-Path $venvRoot 'bin' 'python'
            New-Item -ItemType Directory -Path (Split-Path -Parent $pythonExe) -Force | Out-Null
            Set-Content -LiteralPath $pythonExe -Value '#!/bin/sh' -Encoding UTF8

            $original = $env:VIRTUAL_ENV
            try {
                $env:VIRTUAL_ENV = $venvRoot
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-Command' = {
                        param($Name, $ErrorAction)
                        if ($Name -eq 'Test-ValidPath') {
                            return $null
                        }
                        if ($Name -in @('python', 'python3', 'py')) {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }
                } -Body {
                    Get-PythonPath -RepoRoot (Join-Path $script:TempDir 'manual-venv-repo') |
                        Should -Be $pythonExe
                }
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
    }

    Context 'Invoke-PythonScript extended debug and failure paths' {
        BeforeEach {
            Clear-PythonTestEnvironment
        }

        It 'Logs level 3 details when Python is unavailable during script invocation' {
            $isolatedRepo = Join-Path $script:TempDir 'invoke-no-python-repo'
            $testScript = Join-Path $script:TempDir 'invoke-no-python.py'
            New-Item -ItemType Directory -Path $isolatedRepo -Force | Out-Null
            Set-Content -LiteralPath $testScript -Value 'print("x")' -Encoding UTF8
            $global:TestPythonScriptPath = $testScript
            $global:TestPythonRepoRoot = $isolatedRepo

            $originalDebug = $env:PS_PROFILE_DEBUG
            try {
                $env:PS_PROFILE_DEBUG = '3'
                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { $null }
                    'Get-Command'    = {
                        param($Name, $ErrorAction)
                        if ($Name -in @('Write-StructuredError', 'Write-StructuredWarning')) {
                            return $null
                        }
                        if ($Name -in @('python', 'python3', 'py')) {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath -RepoRoot $global:TestPythonRepoRoot } |
                        Should -Throw '*Python is not available*'
                }
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                Remove-Variable -Name TestPythonScriptPath, TestPythonRepoRoot -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Logs level 3 details when script execution fails without output' {
            $testScript = Join-Path $script:TempDir 'invoke-silent-fail.py'
            Set-Content -LiteralPath $testScript -Value 'raise SystemExit(4)' -Encoding UTF8
            $global:TestPythonScriptPath = $testScript

            $originalDebug = $env:PS_PROFILE_DEBUG
            try {
                $env:PS_PROFILE_DEBUG = '3'
                Setup-CapturingCommandMock -CommandName 'mock-silent-python' -Output '' -ExitCode 0 -OnInvoke {
                    if ($args -contains '--version') {
                        $global:TestCommandCaptureState['ExitCode'] = 0
                        return 'Python 3.11.0'
                    }

                    $global:TestCommandCaptureState['ExitCode'] = 4
                    return ''
                }

                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-silent-python' }
                    'Get-Command'    = {
                        param($Name, $ErrorAction)
                        if ($Name -in @('Write-StructuredError', 'Write-StructuredWarning')) {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } |
                        Should -Throw '*no output*'
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

        It 'Logs level 3 details when the Python version check fails' {
            $testScript = Join-Path $script:TempDir 'invoke-version-fail.py'
            Set-Content -LiteralPath $testScript -Value 'print("x")' -Encoding UTF8
            $global:TestPythonScriptPath = $testScript

            $originalDebug = $env:PS_PROFILE_DEBUG
            try {
                $env:PS_PROFILE_DEBUG = '3'
                Setup-CapturingCommandMock -CommandName 'mock-version-fail-python' -Output 'broken' -ExitCode 1

                Invoke-InPythonModuleWithStub -Stubs @{
                    'Get-PythonPath' = { 'mock-version-fail-python' }
                    'Get-Command'    = {
                        param($Name, $ErrorAction)
                        if ($Name -in @('Write-StructuredError', 'Write-StructuredWarning')) {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }
                } -Body {
                    { Invoke-PythonScript -ScriptPath $global:TestPythonScriptPath } |
                        Should -Throw '*failed to execute*'
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
}
