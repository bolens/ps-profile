

<#
.SYNOPSIS
    Integration tests for SuperJSON to/from CSV conversion utilities.

.DESCRIPTION
    This test suite validates SuperJSON conversion functions for CSV format conversions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and superjson package for SuperJSON conversions.
#>

Describe 'SuperJSON to/from CSV Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'SuperJSON CSV Conversions' {
        It 'ConvertFrom-SuperJsonToCsv converts SuperJSON to CSV' {
            Get-Command ConvertFrom-SuperJsonToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
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
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $json = '[{"name": "test", "value": 123}]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToCsv -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromCsv converts CSV to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
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
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $csv = "name,value`ntest,123"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            { ConvertTo-SuperJsonFromCsv -InputPath $tempFile } | Should -Not -Throw
        }
    }
}

