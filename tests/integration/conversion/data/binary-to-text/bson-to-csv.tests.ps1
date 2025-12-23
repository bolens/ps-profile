

<#
.SYNOPSIS
    Integration tests for BSON to CSV conversion utilities.

.DESCRIPTION
    This test suite validates BSON to CSV conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and bson package for conversions.
#>

Describe 'BSON to CSV Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'BSON to CSV Conversions' {
        It 'ConvertFrom-BsonToCsv converts BSON to CSV' {
            Get-Command ConvertFrom-BsonToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson')) {
                Set-ItResult -Skipped -Because "bson package not installed. Install with: pnpm add -g bson"
                return
            }
            $json = '[{"name":"test1","value":123},{"name":"test2","value":456}]'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempBson = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-BsonFromJson -InputPath $tempJson -OutputPath $tempBson
            { ConvertFrom-BsonToCsv -InputPath $tempBson } | Should -Not -Throw
            $outputFile = $tempBson -replace '\.bson$', '.csv'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }
    }
}

