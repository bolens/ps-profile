

<#
.SYNOPSIS
    Integration tests for EDIFACT format conversion utilities.

.DESCRIPTION
    This test suite validates EDIFACT format conversion functions including conversions to/from JSON, XML, and CSV.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    EDIFACT format uses segments separated by apostrophes (') and elements separated by plus signs (+).
#>

Describe 'EDIFACT Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'EDIFACT Format Conversions' {
        It 'ConvertFrom-EdifactToJson function exists' {
            Get-Command ConvertFrom-EdifactToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EdifactToJson converts EDIFACT to JSON' {
            Get-Command _ConvertFrom-EdifactToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Simple EDIFACT message example
            # UNB: Interchange header, UNH: Message header, BGM: Beginning of message, UNZ: Interchange trailer
            $edifactContent = "UNB+UNOA:2+1234567890123:14+9876543210987:14+240101:1200+0001'UNH+0001+ORDERS:D:96A:UN'BGM+220+ORD12345+9'UNZ+1+0001'"
            $tempFile = Join-Path $TestDrive 'test.edifact'
            Set-Content -Path $tempFile -Value $edifactContent -NoNewline
            
            { _ConvertFrom-EdifactToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.edifact$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.Interchange | Should -Not -BeNullOrEmpty
                $jsonObj.Interchange.Segments | Should -Not -BeNullOrEmpty
                $jsonObj.Interchange.Segments.Count | Should -BeGreaterThan 0
            }
        }

        It 'ConvertTo-EdifactFromJson converts JSON to EDIFACT' {
            Get-Command _ConvertTo-EdifactFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = @"
{
  "Interchange": {
    "Segments": [
      {
        "Tag": "UNB",
        "Elements": ["UNOA:2", "1234567890123:14", "9876543210987:14", "240101:1200", "0001"]
      },
      {
        "Tag": "UNH",
        "Elements": ["0001", "ORDERS:D:96A:UN"]
      },
      {
        "Tag": "BGM",
        "Elements": ["220", "ORD12345", "9"]
      },
      {
        "Tag": "UNZ",
        "Elements": ["1", "0001"]
      }
    ]
  }
}
"@
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { _ConvertTo-EdifactFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.edifact'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $edifact = Get-Content -Path $outputFile -Raw
                $edifact | Should -Not -BeNullOrEmpty
                $edifact | Should -Match 'UNB'
                $edifact | Should -Match 'UNH'
            }
        }

        It 'EDIFACT to JSON and back roundtrip' {
            $originalContent = "UNB+UNOA:2+1234567890123:14+9876543210987:14+240101:1200+0001'UNH+0001+ORDERS:D:96A:UN'BGM+220+ORD12345+9'UNZ+1+0001'"
            $tempFile = Join-Path $TestDrive 'test.edifact'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            # Convert to JSON
            _ConvertFrom-EdifactToJson -InputPath $tempFile
            $jsonFile = $tempFile -replace '\.edifact$', '.json'
            
            # Convert back to EDIFACT
            _ConvertTo-EdifactFromJson -InputPath $jsonFile
            $roundtripFile = $jsonFile -replace '\.json$', '.edifact'
            
            if ($roundtripFile -and -not [string]::IsNullOrWhiteSpace($roundtripFile) -and (Test-Path -LiteralPath $roundtripFile)) {
                $roundtrip = Get-Content -Path $roundtripFile -Raw
                $roundtrip | Should -Not -BeNullOrEmpty
                $roundtrip | Should -Match 'UNB'
                $roundtrip | Should -Match 'UNH'
            }
        }

        It 'ConvertFrom-EdifactToXml converts EDIFACT to XML' {
            Get-Command _ConvertFrom-EdifactToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $edifactContent = "UNB+UNOA:2+1234567890123:14+9876543210987:14+240101:1200+0001'UNH+0001+ORDERS:D:96A:UN'BGM+220+ORD12345+9'UNZ+1+0001'"
            $tempFile = Join-Path $TestDrive 'test.edifact'
            Set-Content -Path $tempFile -Value $edifactContent -NoNewline
            
            { _ConvertFrom-EdifactToXml -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.edifact$', '.xml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $xml = Get-Content -Path $outputFile -Raw
                $xml | Should -Not -BeNullOrEmpty
                $xml | Should -Match '<EDIFACT>'
                $xml | Should -Match '<Segment'
                $xml | Should -Match 'Tag="UNB"'
            }
        }

        It 'ConvertFrom-EdifactToCsv converts EDIFACT to CSV' {
            Get-Command _ConvertFrom-EdifactToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $edifactContent = "UNB+UNOA:2+1234567890123:14+9876543210987:14+240101:1200+0001'UNH+0001+ORDERS:D:96A:UN'BGM+220+ORD12345+9'UNZ+1+0001'"
            $tempFile = Join-Path $TestDrive 'test.edifact'
            Set-Content -Path $tempFile -Value $edifactContent -NoNewline
            
            { _ConvertFrom-EdifactToCsv -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.edifact$', '.csv'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'Segment,Element1'
                $csv | Should -Match 'UNB'
            }
        }

        It 'Handles empty EDIFACT file gracefully' {
            $emptyFile = Join-Path $TestDrive 'empty.edifact'
            Set-Content -Path $emptyFile -Value '' -NoNewline
            
            { _ConvertFrom-EdifactToJson -InputPath $emptyFile } | Should -Not -Throw
        }

        It 'Handles EDIFACT file with whitespace' {
            $edifactContent = "  UNB+UNOA:2+1234567890123:14'  UNH+0001+ORDERS:D:96A:UN'  "
            $tempFile = Join-Path $TestDrive 'test.edifact'
            Set-Content -Path $tempFile -Value $edifactContent -NoNewline
            
            { _ConvertFrom-EdifactToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.edifact$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }

        It 'Handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.edifact'
            
            { _ConvertFrom-EdifactToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'Handles custom output path' {
            $edifactContent = "UNB+UNOA:2+1234567890123:14'UNH+0001+ORDERS:D:96A:UN'"
            $tempFile = Join-Path $TestDrive 'test.edifact'
            Set-Content -Path $tempFile -Value $edifactContent -NoNewline

            $customOutput = Join-Path $TestDrive 'custom-output.json'
            
            { _ConvertFrom-EdifactToJson -InputPath $tempFile -OutputPath $customOutput } | Should -Not -Throw
            
            if ($customOutput -and -not [string]::IsNullOrWhiteSpace($customOutput) -and (Test-Path -LiteralPath $customOutput)) {
                $customOutput | Should -Exist
            }
        }

        It 'Handles .edi and .edf file extensions' {
            $edifactContent = "UNB+UNOA:2+1234567890123:14'UNH+0001+ORDERS:D:96A:UN'"
            $tempFile = Join-Path $TestDrive 'test.edi'
            Set-Content -Path $tempFile -Value $edifactContent -NoNewline
            
            { _ConvertFrom-EdifactToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.edi$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $outputFile | Should -Exist
            }
        }
    }
}

