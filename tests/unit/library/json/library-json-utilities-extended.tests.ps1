<#
tests/unit/library-json-utilities-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for JsonUtilities read/write edge cases.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'ErrorHandling.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $libPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'JsonUtilitiesExtended'
    $script:ProfileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
}

AfterAll {
    Remove-Module JsonUtilities -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'JsonUtilities extended scenarios' {
    Context 'Read-JsonFile' {
        It 'Reads JSON arrays from disk' {
            $file = Join-Path $script:TempRoot 'array.json'
            Set-Content -LiteralPath $file -Value '["alpha","beta","gamma"]' -Encoding UTF8

            $result = @(Read-JsonFile -Path $file)

            @($result).Count | Should -Be 3
            $result | Should -Contain 'alpha'
        }

        It 'Reads nested objects with null values' {
            $file = Join-Path $script:TempRoot 'nested-null.json'
            @'
{
  "Name": "sample",
  "Optional": null
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $result = Read-JsonFile -Path $file

            $result.Name | Should -Be 'sample'
            $result.Optional | Should -BeNullOrEmpty
        }

        It 'Throws for missing files when ErrorAction is Stop' {
            $missing = Join-Path $script:TempRoot 'missing.json'

            { Read-JsonFile -Path $missing -ErrorAction Stop } | Should -Throw '*JSON file not found*'
        }
    }

    Context 'Write-JsonFile' {
        It 'Persists Unicode text without corruption' {
            $file = Join-Path $script:TempRoot 'unicode.json'
            $payload = @{
                Greeting = 'héllo 世界'
                Symbol   = '✓'
            }

            Write-JsonFile -Path $file -InputObject $payload
            $result = Read-JsonFile -Path $file

            $result.Greeting | Should -Be 'héllo 世界'
            $result.Symbol | Should -Be '✓'
        }

        It 'Honors custom serialization depth for deeply nested objects' {
            $file = Join-Path $script:TempRoot 'depth.json'
            $payload = @{
                Level1 = @{
                    Level2 = @{
                        Level3 = @{
                            Value = 'deep'
                        }
                    }
                }
            }

            Write-JsonFile -Path $file -InputObject $payload -Depth 2
            $raw = Get-Content -LiteralPath $file -Raw

            $raw | Should -Match 'Level1'
            $raw | Should -Not -Match '"Value": "deep"'
        }

        It 'Creates parent directories when EnsureDirectory is specified' {
            $file = Join-Path $script:TempRoot 'ensure-dir' 'nested' 'output.json'
            Write-JsonFile -Path $file -InputObject @{ Name = 'created' } -EnsureDirectory

            Test-Path -LiteralPath $file | Should -Be $true
            (Read-JsonFile -Path $file).Name | Should -Be 'created'
        }

        It 'Returns null for write failures when ErrorAction is SilentlyContinue' {
            $file = Join-Path $script:TempRoot 'write-failure.json'
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR = '1'

            try {
                $result = Write-JsonFile -Path $file -InputObject @{ Value = 1 } -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR = $originalFlag
                }
            }
        }
    }

    Context 'JsonUtilities test environment hooks' {
        It 'Uses plain warnings for empty JSON files when structured warnings are disabled' {
            $file = Join-Path $script:TempRoot 'empty-warning.json'
            Set-Content -LiteralPath $file -Value '' -Encoding UTF8
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING
            $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING = '1'

            try {
                $result = Read-JsonFile -Path $file -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING = $originalFlag
                }
            }
        }

        It 'Returns null for forced read failures with SilentlyContinue' {
            $file = Join-Path $script:TempRoot 'valid.json'
            @{ Name = 'sample' } | ConvertTo-Json | Set-Content -LiteralPath $file -Encoding UTF8
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_FORCE_READ_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_FORCE_READ_ERROR = '1'

            try {
                $result = Read-JsonFile -Path $file -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_FORCE_READ_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_FORCE_READ_ERROR = $originalFlag
                }
            }
        }

        It 'Uses plain errors when structured logging is disabled for write failures' {
            $file = Join-Path $script:TempRoot 'plain-write-error.json'
            $originalWriteFlag = $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR
            $originalStructuredFlag = $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR = '1'
            $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = '1'

            try {
                { Write-JsonFile -Path $file -InputObject @{ Value = 1 } -ErrorAction Stop } | Should -Throw
            }
            finally {
                if ($null -eq $originalWriteFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR = $originalWriteFlag
                }

                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }
            }
        }

        It 'Uses structured warnings for empty JSON files when error handling is available' {
            $globalState = Join-Path $script:ProfileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $script:ProfileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $script:ProfileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) {
                . $globalState
            }
            if (Test-Path -LiteralPath $functionRegistration) {
                . $functionRegistration
            }
            if (Test-Path -LiteralPath $errorHandlingPath) {
                . $errorHandlingPath
            }

            $file = Join-Path $script:TempRoot 'structured-empty.json'
            Set-Content -LiteralPath $file -Value '' -Encoding UTF8

            $result = Read-JsonFile -Path $file -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Uses structured errors for missing files when error handling is available' {
            $globalState = Join-Path $script:ProfileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $script:ProfileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $script:ProfileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) {
                . $globalState
            }
            if (Test-Path -LiteralPath $functionRegistration) {
                . $functionRegistration
            }
            if (Test-Path -LiteralPath $errorHandlingPath) {
                . $errorHandlingPath
            }

            $missing = Join-Path $script:TempRoot 'structured-missing.json'
            { Read-JsonFile -Path $missing -ErrorAction Stop } | Should -Throw '*JSON file not found*'
        }

        It 'Handles mkdir failures when EnsureDirectory is enabled' {
            $file = Join-Path $script:TempRoot 'mkdir-failure' 'nested' 'output.json'
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR = '1'

            try {
                { Write-JsonFile -Path $file -InputObject @{ Value = 1 } -EnsureDirectory -ErrorAction Stop } | Should -Throw
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR = $originalFlag
                }
            }
        }

        It 'Uses Get-ErrorActionPreference when ErrorHandling module is loaded' {
            $file = Join-Path $script:TempRoot 'continue-missing.json'
            $result = Read-JsonFile -Path $file -ErrorAction Continue
            $result | Should -BeNullOrEmpty
        }

        It 'Writes JSON using a non-default encoding parameter' {
            $file = Join-Path $script:TempRoot 'ascii-encoded.json'
            Write-JsonFile -Path $file -InputObject @{ Name = 'ascii' } -Encoding 'ASCII'
            $raw = Get-Content -LiteralPath $file -Raw
            $raw | Should -Match 'ascii'
        }

        It 'Emits write debug output when PS_PROFILE_DEBUG is enabled' {
            $file = Join-Path $script:TempRoot 'debug-write.json'
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Write-JsonFile -Path $file -InputObject @{ Name = 'debug-write' }
                Test-Path -LiteralPath $file | Should -Be $true
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

        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $file = Join-Path $script:TempRoot 'debug-read.json'
            @{ Name = 'debug' } | ConvertTo-Json | Set-Content -LiteralPath $file -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Read-JsonFile -Path $file
                $result.Name | Should -Be 'debug'
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

        It 'Uses plain errors for invalid JSON when structured logging is disabled' {
            $file = Join-Path $script:TempRoot 'invalid-plain.json'
            Set-Content -LiteralPath $file -Value '{ not-json' -Encoding UTF8
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = '1'

            try {
                { Read-JsonFile -Path $file -ErrorAction Stop } | Should -Throw
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = $originalFlag
                }
            }
        }

        It 'Uses plain errors for missing files when structured logging is disabled' {
            $missing = Join-Path $script:TempRoot 'plain-missing.json'
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = '1'

            try {
                { Read-JsonFile -Path $missing -ErrorAction Stop } | Should -Throw '*JSON file not found*'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = $originalFlag
                }
            }
        }

        It 'Uses plain warnings for empty files at debug level 1 when structured logging is disabled' {
            $file = Join-Path $script:TempRoot 'plain-empty-warning.json'
            Set-Content -LiteralPath $file -Value '' -Encoding UTF8
            $originalWarningFlag = $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = Read-JsonFile -Path $file -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalWarningFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_WARNING = $originalWarningFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses plain write errors when structured logging is disabled' {
            $file = Join-Path $script:TempRoot 'plain-write-error.json'
            $originalWriteFlag = $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR
            $originalStructuredFlag = $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR
            $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR = '1'
            $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = '1'

            try {
                { Write-JsonFile -Path $file -InputObject @{ Value = 1 } -ErrorAction Stop } | Should -Throw
            }
            finally {
                if ($null -eq $originalWriteFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_FORCE_WRITE_ERROR = $originalWriteFlag
                }

                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }
            }
        }

        It 'Emits structured read errors for invalid JSON when error handling is available' {
            $globalState = Join-Path $script:ProfileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $script:ProfileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $script:ProfileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $file = Join-Path $script:TempRoot 'structured-invalid.json'
            Set-Content -LiteralPath $file -Value '{ invalid' -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Read-JsonFile -Path $file -ErrorAction Stop } | Should -Throw '*Failed to read JSON file*'
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

        It 'Creates parent directories with New-Item when FileSystem helpers are unavailable' {
            Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
            $file = Join-Path $script:TempRoot 'fallback-dir' 'created.json'
            Write-JsonFile -Path $file -InputObject @{ Created = $true } -EnsureDirectory
            Test-Path -LiteralPath $file | Should -Be $true
        }

        It 'Falls back to manual ErrorAction extraction when ErrorHandling is unavailable' {
            Remove-Module ErrorHandling -ErrorAction SilentlyContinue -Force
            $missing = Join-Path $script:TempRoot 'manual-error-action.json'

            { Read-JsonFile -Path $missing -ErrorAction Continue } | Should -Not -Throw
            (Read-JsonFile -Path $missing -ErrorAction Continue) | Should -BeNullOrEmpty
        }

        It 'Emits structured missing-file errors with debug level 3' {
            $globalState = Join-Path $script:ProfileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $script:ProfileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $script:ProfileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $missing = Join-Path $script:TempRoot 'debug-missing.json'
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Read-JsonFile -Path $missing -ErrorAction Stop } | Should -Throw '*JSON file not found*'
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

        It 'Emits structured mkdir failure details when EnsureDirectory is enabled' {
            $globalState = Join-Path $script:ProfileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $script:ProfileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $script:ProfileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $file = Join-Path $script:TempRoot 'mkdir-structured' 'nested' 'output.json'
            $originalFlag = $env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Write-JsonFile -Path $file -InputObject @{ Value = 1 } -EnsureDirectory -ErrorAction Stop } | Should -Throw
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_JSON_UTILITIES_FORCE_MKDIR_ERROR = $originalFlag
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
}
