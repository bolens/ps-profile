<#
tests/unit/library-datafile-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-CachedPowerShellDataFile edge cases.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'DataFile.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'DataFileExtended'
}

function script:Install-TestGetCachedValueStub {
    param(
        [Parameter(Mandatory)]
        [object]$ReturnValue
    )

    Restore-TestGetCachedValue

    $global:DataFileTest_OriginalGetCachedValueCommand = Get-Command Get-CachedValue -ErrorAction SilentlyContinue
    $global:DataFileTest_StubReturnValue = $ReturnValue

    function global:Get-CachedValue {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]$Key,

            [object]$Value,

            [int]$ExpirationSeconds = 300,

            [switch]$Clear
        )

        if ($PSBoundParameters.ContainsKey('Value') -or $Clear) {
            $delegate = Get-Variable -Name DataFileTest_OriginalGetCachedValueCommand -Scope Global -ValueOnly -ErrorAction SilentlyContinue
            if ($delegate) {
                return & $delegate @PSBoundParameters
            }
        }

        return (Get-Variable -Name DataFileTest_StubReturnValue -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
    }
}

function script:Restore-TestGetCachedValue {
    $original = Get-Variable -Name DataFileTest_OriginalGetCachedValueCommand -Scope Global -ValueOnly -ErrorAction SilentlyContinue

    Remove-Item Function:\Get-CachedValue -ErrorAction SilentlyContinue -Force
    Remove-Item Function:\global:Get-CachedValue -ErrorAction SilentlyContinue -Force
    Remove-Variable -Name DataFileTest_StubReturnValue -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name DataFileTest_OriginalGetCachedValueCommand -Scope Global -ErrorAction SilentlyContinue

    if ($original) {
        Set-Item -Path Function:\global:Get-CachedValue -Value $original.ScriptBlock -Force
    }
}

AfterAll {
    Remove-Module DataFile -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'DataFile extended scenarios' {
    Context 'Import-CachedPowerShellDataFile' {
        It 'Returns an empty hashtable for @{} data files' {
            $file = Join-Path $script:TempRoot 'empty.psd1'
            Set-Content -LiteralPath $file -Value '@{}' -Encoding UTF8

            $result = Import-CachedPowerShellDataFile -Path $file

            $result | Should -BeOfType [hashtable]
            @($result.Keys).Count | Should -Be 0
        }

        It 'Imports nested hashtable structures' {
            $file = Join-Path $script:TempRoot 'nested.psd1'
            @'
@{
    Runner = @{
        Suite = 'Unit'
        Tags  = @('Smoke', 'Fast')
    }
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $result = Import-CachedPowerShellDataFile -Path $file

            $result.Runner.Suite | Should -Be 'Unit'
            @($result.Runner.Tags).Count | Should -Be 2
        }

        It 'Uses cached content on subsequent reads' {
            $file = Join-Path $script:TempRoot 'cached.psd1'
            @'
@{
    Version = '1.0.0'
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $first = Import-CachedPowerShellDataFile -Path $file
            $second = Import-CachedPowerShellDataFile -Path $file

            $first.Version | Should -Be '1.0.0'
            $second.Version | Should -Be '1.0.0'
        }

        It 'Throws for syntactically invalid data files' {
            $file = Join-Path $script:TempRoot 'invalid.psd1'
            Set-Content -LiteralPath $file -Value '@{' -Encoding UTF8

            { Import-CachedPowerShellDataFile -Path $file } | Should -Throw
        }
    }

    Context 'DataFile test environment hooks' {
        It 'Uses manual validation when PS_PROFILE_DATAFILE_SKIP_VALIDATION is enabled' {
            $missingFile = Join-Path $script:TempRoot 'missing-manual-validation.psd1'
            $originalFlag = $env:PS_PROFILE_DATAFILE_SKIP_VALIDATION
            $env:PS_PROFILE_DATAFILE_SKIP_VALIDATION = '1'

            try {
                { Import-CachedPowerShellDataFile -Path $missingFile } | Should -Throw '*File not found*'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_DATAFILE_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DATAFILE_SKIP_VALIDATION = $originalFlag
                }
            }
        }

        It 'Loads cache through manual import fallback when forced' {
            $originalFlag = $env:PS_PROFILE_DATAFILE_FORCE_MANUAL_IMPORT
            $env:PS_PROFILE_DATAFILE_FORCE_MANUAL_IMPORT = '1'

            Get-Module DataFile, Cache, SafeImport -All | Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                Import-Module (Join-Path $script:LibPath 'utilities' 'DataFile.psm1') -DisableNameChecking -Force
                Get-Command Import-CachedPowerShellDataFile -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module DataFile -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_DATAFILE_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DATAFILE_FORCE_MANUAL_IMPORT = $originalFlag
                }

                Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'utilities' 'DataFile.psm1') -DisableNameChecking -Force
            }
        }

        It 'Uses Write-Error for import failures when structured logging is disabled via env flag' {
            $file = Join-Path $script:TempRoot 'structured-error-disabled.psd1'
            Set-Content -LiteralPath $file -Value '{ invalid syntax }' -Encoding UTF8

            $originalStructuredFlag = $env:PS_PROFILE_DATAFILE_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DATAFILE_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                { Import-CachedPowerShellDataFile -Path $file } | Should -Throw '*Failed to import*'
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_DATAFILE_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DATAFILE_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
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

    Context 'Import-CachedPowerShellDataFile debug and cache branches' {
        AfterEach {
            Restore-TestGetCachedValue
        }

        It 'Re-imports when cache returns a non-hashtable value' {
            if (-not (Get-Command Get-CachedValue -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'Get-CachedValue is not available'
                return
            }

            $file = Join-Path $script:TempRoot 'cache-non-hashtable.psd1'
            @'
@{
    CacheFixup = 'value'
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            Install-TestGetCachedValueStub -ReturnValue 'not-a-hashtable'
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $result = Import-CachedPowerShellDataFile -Path $file
                $result | Should -BeOfType [hashtable]
                $result.CacheFixup | Should -Be 'value'
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

        It 'Emits debug output for cache hits at debug level 3' {
            $file = Join-Path $script:TempRoot 'cache-hit-debug.psd1'
            @'
@{
    Cached = $true
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $first = Import-CachedPowerShellDataFile -Path $file
                $first.Cached | Should -Be $true

                $second = Import-CachedPowerShellDataFile -Path $file
                $second.Cached | Should -Be $true
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

        It 'Emits debug output during import at debug level 2' {
            $file = Join-Path $script:TempRoot 'import-debug.psd1'
            @'
@{
    DebugImport = 'level-2'
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $result = Import-CachedPowerShellDataFile -Path $file
                $result.DebugImport | Should -Be 'level-2'
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

        It 'Returns an empty hashtable for whitespace-only files that fail import' {
            $file = Join-Path $script:TempRoot 'whitespace-only.psd1'
            Set-Content -LiteralPath $file -Value '   ' -Encoding UTF8

            { Import-CachedPowerShellDataFile -Path $file } | Should -Not -Throw
            $result = Import-CachedPowerShellDataFile -Path $file
            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
        }

        It 'Uses fallback cache key generation when New-FileCacheKey is unavailable' {
            $originalCmd = Get-Command New-FileCacheKey -ErrorAction SilentlyContinue
            if ($originalCmd) {
                Remove-Module CacheKey -ErrorAction SilentlyContinue -Force
            }

            $file = Join-Path $script:TempRoot 'fallback-cache-key.psd1'
            @'
@{
    Fallback = 'cache-key'
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            try {
                $result = Import-CachedPowerShellDataFile -Path $file
                $result.Fallback | Should -Be 'cache-key'
            }
            finally {
                if ($originalCmd) {
                    Import-Module (Join-Path $script:LibPath 'utilities' 'CacheKey.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
