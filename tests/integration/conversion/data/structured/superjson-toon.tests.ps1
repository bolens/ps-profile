

<#
.SYNOPSIS
    Integration tests for SuperJSON to/from TOON conversion utilities.

.DESCRIPTION
    This test suite validates SuperJSON conversion functions for TOON format conversions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and superjson package for SuperJSON conversions.
#>

Describe 'SuperJSON to/from TOON Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir

        $repoRoot = Split-Path -Parent $script:ProfileDir
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }

        $script:InvokeNodeScriptAvailable = (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'SuperJSON TOON Conversions' {
        It 'ConvertFrom-SuperJsonToToon converts SuperJSON to TOON' {
            Get-Command ConvertFrom-SuperJsonToToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'superjson' -ToolType 'node-package' -Context 'superjson package not installed')
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToToon -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromToon converts TOON to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'superjson' -ToolType 'node-package' -Context 'superjson package not installed')
                return
            }
            $toon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertTo-SuperJsonFromToon -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToToon and ConvertTo-SuperJsonFromToon roundtrip' {
            Get-Command ConvertFrom-SuperJsonToToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'superjson' -ToolType 'node-package' -Context 'superjson package not installed')
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToToon -InputPath $superjsonFile } | Should -Not -Throw
                $toonFile = $superjsonFile -replace '\.superjson$', '.toon'
                if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                    { ConvertTo-SuperJsonFromToon -InputPath $toonFile } | Should -Not -Throw
                }
            }
        }
    }
}

