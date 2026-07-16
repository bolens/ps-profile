<#
tests/unit/library-chocolatey-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ChocolateyDetection root resolution edge cases.
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
    $script:LibPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $script:LibPath 'core/CommonEnums.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $script:LibPath 'runtime/ChocolateyDetection.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ChocolateyDetectionExtended'
    $script:FakeChocoRoot = Join-Path $script:TempDir 'chocolatey'
    New-Item -ItemType Directory -Path (Join-Path $script:FakeChocoRoot 'lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:FakeChocoRoot 'bin') -Force | Out-Null
}

function script:Clear-ChocolateyTestEnvironment {
    foreach ($name in @(
            'ChocolateyInstall'
            'ChocolateyPath'
            'ChocolateyToolsLocation'
            'ChocolateyBinRoot'
            'ProgramData'
            'PS_PROFILE_DEBUG'
        )) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }
    if (Get-Command Clear-CommandTestStubs -ErrorAction SilentlyContinue) {
        Clear-CommandTestStubs
    }
}

function script:Disable-ChocolateyDefaultLocations {
    <#
    .SYNOPSIS
        Isolate detection from a host Chocolatey install (ProgramData + hardcoded fallback).
    #>
    $emptyProgramData = Join-Path $script:TempDir 'empty-programdata'
    if (-not (Test-Path -LiteralPath $emptyProgramData)) {
        New-Item -ItemType Directory -Path $emptyProgramData -Force | Out-Null
    }
    Mock-EnvironmentVariable -Name 'ProgramData' -Value $emptyProgramData

    Mock Get-Command {
        $cmdName = $Name
        if ([string]::IsNullOrWhiteSpace($cmdName) -and $args.Count -gt 0) {
            $cmdName = [string]$args[0]
        }
        if ($cmdName -eq 'Test-ValidPath') {
            return $null
        }
        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
    } -ModuleName ChocolateyDetection

    Mock Test-Path {
        $target = $null
        if ($PSBoundParameters.ContainsKey('LiteralPath') -and $LiteralPath) {
            $target = [string]$LiteralPath
        }
        elseif ($PSBoundParameters.ContainsKey('Path') -and $Path) {
            $target = [string]$Path
        }
        elseif ($args.Count -gt 0) {
            $target = [string]$args[0]
        }
        if ($target -eq 'C:\ProgramData\chocolatey') {
            return $false
        }
        return Microsoft.PowerShell.Management\Test-Path @PSBoundParameters
    } -ModuleName ChocolateyDetection
}

AfterAll {
    Clear-ChocolateyTestEnvironment
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function script:Mock-ChocolateyGetCommandWithoutChoco {
    <#
    .SYNOPSIS
        Module-scoped Get-Command mock that hides choco without breaking other probes.
    #>
    # Pester 5.6+/6 require a default mock when -ModuleName is used with -ParameterFilter,
    # otherwise unmatched calls (Test-ValidPath, Write-StructuredWarning) throw.
    Mock Get-Command {
        $cmdName = $Name
        if ([string]::IsNullOrWhiteSpace($cmdName) -and $args.Count -gt 0) {
            $cmdName = [string]$args[0]
        }

        if ($cmdName -eq 'choco') {
            return $null
        }

        # Keep ChocolateyDetection on its Test-Path fallbacks; do not surface global-only helpers.
        if ($cmdName -eq 'Test-ValidPath') {
            return $null
        }

        # Prefer callable global stubs (Enable-TestStructuredLogging) over module-only exports.
        if ($cmdName -in @('Write-StructuredWarning', 'Write-StructuredError')) {
            $globalFn = Get-Item -Path "Function:\global:$cmdName" -ErrorAction SilentlyContinue
            if ($globalFn) {
                return Microsoft.PowerShell.Core\Get-Command -Name $cmdName -CommandType Function -ErrorAction SilentlyContinue
            }
            return $null
        }

        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
    } -ModuleName ChocolateyDetection
}

Describe 'ChocolateyDetection extended scenarios' {
    BeforeEach { Clear-ChocolateyTestEnvironment }
    AfterEach {
        # Use module-qualified Get-Command so filtered Get-Command mocks cannot break cleanup.
        $restoreMocks = Microsoft.PowerShell.Core\Get-Command -Name Restore-AllMocks -ErrorAction SilentlyContinue
        if ($restoreMocks) {
            & $restoreMocks
        }
    }

    Context 'Get-ChocolateyRoot' {
        It 'Ignores ChocolateyInstall values that are not directories' {
            $filePath = Join-Path $script:TempDir 'missing-choco.txt'
            New-Item -ItemType File -Path $filePath -Force | Out-Null
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $filePath
            Disable-ChocolateyDefaultLocations

            Get-ChocolateyRoot | Should -BeNullOrEmpty
        }

        It 'Detects roots from ChocolateyInstall when lib exists beneath it' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }

        It 'Detects roots from ChocolateyPath when the directory contains lib' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            $env:ChocolateyPath = $script:FakeChocoRoot

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }

        It 'Resolves parent directories from ChocolateyToolsLocation values' {
            $toolsSubdir = Join-Path $script:FakeChocoRoot 'tools'
            New-Item -ItemType Directory -Path $toolsSubdir -Force | Out-Null
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            $env:ChocolateyToolsLocation = $toolsSubdir

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }

        It 'Detects roots from ProgramData when chocolatey exists there' {
            $programDataRoot = Join-Path $script:TempDir 'program-data'
            $chocoInProgramData = Join-Path $programDataRoot 'chocolatey'
            New-Item -ItemType Directory -Path (Join-Path $chocoInProgramData 'lib') -Force | Out-Null
            Mock-EnvironmentVariable -Name 'ProgramData' -Value $programDataRoot

            Get-ChocolateyRoot | Should -Be $chocoInProgramData
        }

        It 'Logs ProgramData discovery details at debug level 3' {
            $programDataRoot = Join-Path $script:TempDir 'program-data-debug'
            $chocoInProgramData = Join-Path $programDataRoot 'chocolatey'
            New-Item -ItemType Directory -Path (Join-Path $chocoInProgramData 'lib') -Force | Out-Null
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            Mock-EnvironmentVariable -Name 'ProgramData' -Value $programDataRoot
            $env:PS_PROFILE_DEBUG = '3'

            Get-ChocolateyRoot | Should -Be $chocoInProgramData
        }

        It 'Logs debug details when ChocolateyInstall resolves successfully at level 3' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot
            $env:PS_PROFILE_DEBUG = '3'

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }

        It 'Logs verbose output when no Chocolatey root is found at debug level 2' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            Disable-ChocolateyDefaultLocations
            $env:PS_PROFILE_DEBUG = '2'

            Get-ChocolateyRoot | Should -BeNullOrEmpty
        }

        It 'Detects roots from ChocolateyBinRoot when the directory contains lib' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            $env:ChocolateyBinRoot = $script:FakeChocoRoot

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }
    }

    Context 'Get-ChocolateyLibPath and Get-ChocolateyBinPath' {
        It 'Uses an explicit ChocolateyRoot parameter without auto-detection' {
            Get-ChocolateyLibPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'lib')
        }

        It 'Returns null for bin path when the bin directory is missing under an explicit root' {
            $libOnlyRoot = Join-Path $script:TempDir 'lib-only-choco'
            New-Item -ItemType Directory -Path (Join-Path $libOnlyRoot 'lib') -Force | Out-Null

            Get-ChocolateyBinPath -ChocolateyRoot $libOnlyRoot | Should -BeNullOrEmpty
        }

        It 'Returns bin path when bin exists under an explicit root' {
            Get-ChocolateyBinPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'bin')
        }

        It 'Logs lib path debug details at level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            Get-ChocolateyLibPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'lib')
        }

        It 'Logs missing lib path details at debug level 2' {
            $libOnlyRoot = Join-Path $script:TempDir 'missing-lib-root'
            New-Item -ItemType Directory -Path $libOnlyRoot -Force | Out-Null
            $env:PS_PROFILE_DEBUG = '2'

            Get-ChocolateyLibPath -ChocolateyRoot $libOnlyRoot | Should -BeNullOrEmpty
        }

        It 'Logs missing bin path details at debug level 2' {
            $libOnlyRoot = Join-Path $script:TempDir 'missing-bin-root'
            New-Item -ItemType Directory -Path (Join-Path $libOnlyRoot 'lib') -Force | Out-Null
            $env:PS_PROFILE_DEBUG = '2'

            Get-ChocolateyBinPath -ChocolateyRoot $libOnlyRoot | Should -BeNullOrEmpty
        }

        It 'Uses manual path validation for lib paths when Test-ValidPath is unavailable' {
            Remove-TestFunction -Name 'Test-ValidPath'

            Get-ChocolateyLibPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'lib')
        }

        It 'Uses manual path validation for bin paths when Test-ValidPath is unavailable' {
            Remove-TestFunction -Name 'Test-ValidPath'

            Get-ChocolateyBinPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'bin')
        }

        It 'Logs bin path discovery details at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            Get-ChocolateyBinPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'bin')
        }
    }

    Context 'Test-ChocolateyInstalled' {
        BeforeEach {
            if (Get-Command Clear-CommandTestStubs -ErrorAction SilentlyContinue) {
                Clear-CommandTestStubs
            }
            Remove-TestFunction -Name 'choco'
        }

        It 'Requires choco command when CheckCommand is specified' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot
            Mock-ChocolateyGetCommandWithoutChoco

            Test-ChocolateyInstalled -CheckCommand | Should -Be $false
        }

        It 'Returns true when root exists and choco command is available' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'choco help'

            Test-ChocolateyInstalled -CheckCommand | Should -Be $true
        }

        It 'Emits structured warnings when root exists but choco command is missing with debug enabled' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot
            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging
            Mock-ChocolateyGetCommandWithoutChoco

            Test-ChocolateyInstalled -CheckCommand | Should -Be $false
        }

        It 'Returns true when Chocolatey root exists without command verification' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot
            $env:PS_PROFILE_DEBUG = '2'

            Test-ChocolateyInstalled | Should -Be $true
        }

        It 'Uses plain warnings when structured logging is unavailable' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot
            $env:PS_PROFILE_DEBUG = '1'
            Remove-TestFunction -Name 'Write-StructuredWarning'
            Mock-ChocolateyGetCommandWithoutChoco

            Test-ChocolateyInstalled -CheckCommand -WarningAction SilentlyContinue | Should -Be $false
        }
    }
}
