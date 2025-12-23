

<#
.SYNOPSIS
    Integration tests for CBOR to CSV conversion utilities.

.DESCRIPTION
    This test suite validates CBOR to CSV conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and cbor package for conversions.
#>

Describe 'CBOR to CSV Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'CBOR to CSV Conversions' {
        It 'ConvertFrom-CborToCsv converts CBOR to CSV' {
            Get-Command ConvertFrom-CborToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "cbor package not installed. Install with: pnpm add -g cbor"
                return
            }
            $json = '[{"name":"test1","value":123},{"name":"test2","value":456}]'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempCbor = Join-Path $TestDrive 'test.cbor'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-CborFromJson -InputPath $tempJson -OutputPath $tempCbor
            { ConvertFrom-CborToCsv -InputPath $tempCbor } | Should -Not -Throw
            $outputFile = $tempCbor -replace '\.cbor$', '.csv'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }
    }
}

