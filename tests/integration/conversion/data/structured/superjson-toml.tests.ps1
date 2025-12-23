

<#
.SYNOPSIS
    Integration tests for SuperJSON to/from TOML conversion utilities.

.DESCRIPTION
    This test suite validates SuperJSON conversion functions for TOML format conversions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js, superjson package, yq, and PSToml for SuperJSON conversions.
#>

Describe 'SuperJSON to/from TOML Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'SuperJSON TOML Conversions' {
        It 'ConvertFrom-SuperJsonToToml converts SuperJSON to TOML' {
            Get-Command ConvertFrom-SuperJsonToToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Skip if PSToml not available
            if (-not (Get-Module -ListAvailable -Name PSToml -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "PSToml module not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToToml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromToml converts TOML to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $toml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $toml
            { ConvertTo-SuperJsonFromToml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToToml and ConvertTo-SuperJsonFromToml roundtrip' {
            Get-Command ConvertFrom-SuperJsonToToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Skip if PSToml not available
            if (-not (Get-Module -ListAvailable -Name PSToml -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "PSToml module not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $originalToml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $originalToml
            { ConvertTo-SuperJsonFromToml -InputPath $tempFile } | Should -Not -Throw
            $superjsonFile = $tempFile -replace '\.toml$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToToml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }
    }
}

